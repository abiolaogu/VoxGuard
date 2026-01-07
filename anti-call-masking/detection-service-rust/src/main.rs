use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};
use chrono::{DateTime, Utc};
use redis::AsyncCommands;
use serde::{Deserialize, Serialize};
use std::env;
use std::sync::Arc;
use tokio::sync::mpsc;

// Configuration
#[derive(Clone)]
struct AppState {
    redis_client: redis::Client,
    clickhouse_url: String,
    window_seconds: i64,
    threshold: usize,
    clickhouse_sender: mpsc::Sender<CallEvent>,
}

// Data Models
#[derive(Serialize, Deserialize, Debug, Clone)]
struct CallEvent {
    call_id: String,
    a_number: String,
    b_number: String,
    #[serde(default = "default_timestamp")]
    timestamp: DateTime<Utc>,
}

fn default_timestamp() -> DateTime<Utc> {
    Utc::now()
}

#[derive(Serialize, Debug)]
struct Alert {
    alert_id: String,
    b_number: String,
    call_count: usize,
    created_at: DateTime<Utc>,
    description: String,
}

// ClickHouse Async Writer Background Task
async fn clickhouse_writer(mut rx: mpsc::Receiver<CallEvent>, clickhouse_url: String) {
    let client = reqwest::Client::new();
    let url = format!("{}/?query=INSERT INTO calls FORMAT JSONEachRow", clickhouse_url);

    // Naive batching implementation 
    // In prod, use a proper buffer with flush interval
    while let Some(event) = rx.recv().await {
        // Send immediately for now, but async so it doesn't block response
        let _ = client.post(&url)
            .json(&event)
            .send()
            .await;
    }
}

// Handlers
#[post("/event")]
async fn handle_event(
    event: web::Json<CallEvent>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut con = match data.redis_client.get_async_connection().await {
        Ok(c) => c,
        Err(e) => return HttpResponse::InternalServerError().body(format!("Redis error: {}", e)),
    };

    let b_key = format!("window:{}", event.b_number);
    let a_val = &event.a_number;

    // 1. Add to Dragonfly/Redis Set with Expiry (Rolling Window)
    // Pipeline for latency
    let _: () = redis::pipe()
        .sadd(&b_key, a_val)
        .expire(&b_key, data.window_seconds as usize)
        .query_async(&mut con)
        .await
        .unwrap_or(());

    // 2. Check Cardinality (SCARD)
    let count: usize = con.scard(&b_key).await.unwrap_or(0);
    
    // 3. Async Write to ClickHouse (Fire and Forget)
    let _ = data.clickhouse_sender.send(event.0.clone()).await;

    // 4. Check Threshold
    if count >= data.threshold {
        // Log Alert (In real world, push to Alert System/Kafka)
        log::warn!("FRAUD DETECTED: B-Number {} has {} distinct callers", event.b_number, count);
        
        let alert = Alert {
            alert_id: format!("ALERT-{}", Utc::now().timestamp_nanos()),
            b_number: event.b_number.clone(),
            call_count: count,
            created_at: Utc::now(),
            description: "Masking Attack Detected".to_string(),
        };
        
        // Return 200 with Alert
        // We return 200 to not break flow, but include alert info
        return HttpResponse::Ok().json(serde_json::json!({
            "status": "alert",
            "alert": alert
        }));
    }

    HttpResponse::Ok().json(serde_json::json!({"status": "processed"}))
}

#[get("/health")]
async fn health() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "Rust Detection Service",
        "db": "ClickHouse + DragonflyDB"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    dotenv::dotenv().ok();

    let redis_url = env::var("REDIS_URL").unwrap_or_else(|_| "redis://dragonfly:6379".to_string());
    let clickhouse_url = env::var("CLICKHOUSE_URL").unwrap_or_else(|_| "http://clickhouse:8123".to_string());
    
    let redis_client = redis::Client::open(redis_url).expect("Invalid Redis URL");

    // Channel for ClickHouse writing
    let (tx, rx) = mpsc::channel(10000);
    
    // Spawn ClickHouse writer
    let ch_url_clone = clickhouse_url.clone();
    tokio::spawn(async move {
        clickhouse_writer(rx, ch_url_clone).await;
    });

    let state = AppState {
        redis_client,
        clickhouse_url,
        window_seconds: env::var("DETECTION_WINDOW_SECONDS").unwrap_or("5".into()).parse().unwrap(),
        threshold: env::var("DETECTION_THRESHOLD").unwrap_or("5".into()).parse().unwrap(),
        clickhouse_sender: tx,
    };

    println!("Starting Rust Detection Service on :8080");

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(state.clone()))
            .service(handle_event)
            .service(health)
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
