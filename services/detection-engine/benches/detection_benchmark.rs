//! Performance Benchmarks for ACM Detection Engine
//!
//! Target: 150K+ CPS (calls per second) with <1ms P99 latency
//!
//! Run benchmarks: cargo bench

use criterion::{black_box, criterion_group, criterion_main, Criterion, Throughput, BenchmarkId};
use std::time::Duration;

// Declare lib module for benchmarks
use acm_detection::domain::value_objects::{MSISDN, IPAddress, FraudScore, DetectionWindow, DetectionThreshold};

/// Benchmark MSISDN parsing performance
fn bench_msisdn_parsing(c: &mut Criterion) {
    let numbers = vec![
        "+2348012345678",
        "2348098765432", 
        "08012345678",
        "+2348033333333",
    ];

    let mut group = c.benchmark_group("msisdn");
    group.throughput(Throughput::Elements(1));
    
    for number in &numbers {
        group.bench_with_input(BenchmarkId::from_parameter(number), number, |b, n| {
            b.iter(|| MSISDN::new(black_box(n)))
        });
    }
    group.finish();
}

/// Benchmark IP Address parsing
fn bench_ip_parsing(c: &mut Criterion) {
    let ips = vec!["192.168.1.1", "10.0.0.1", "172.16.0.1", "8.8.8.8"];
    
    let mut group = c.benchmark_group("ip_address");
    group.throughput(Throughput::Elements(1));
    
    for ip in &ips {
        group.bench_with_input(BenchmarkId::from_parameter(ip), ip, |b, i| {
            b.iter(|| IPAddress::new(black_box(i)))
        });
    }
    group.finish();
}

/// Benchmark fraud score calculations
fn bench_fraud_score(c: &mut Criterion) {
    let mut group = c.benchmark_group("fraud_score");
    group.throughput(Throughput::Elements(1));
    
    for score in [0.1, 0.5, 0.75, 0.9, 0.95] {
        group.bench_with_input(BenchmarkId::from_parameter(format!("{:.2}", score)), &score, |b, s| {
            b.iter(|| {
                let fs = FraudScore::new(black_box(*s));
                black_box(fs.severity())
            })
        });
    }
    group.finish();
}

/// Benchmark value object creation (simulates call processing overhead)
fn bench_call_value_objects(c: &mut Criterion) {
    let mut group = c.benchmark_group("call_creation");
    group.throughput(Throughput::Elements(1));
    group.measurement_time(Duration::from_secs(10));
    
    group.bench_function("full_call_vo_creation", |b| {
        b.iter(|| {
            let a_number = MSISDN::new(black_box("+2348012345678")).unwrap();
            let b_number = MSISDN::new(black_box("+2348098765432")).unwrap();
            let source_ip = IPAddress::new(black_box("192.168.1.1")).unwrap();
            black_box((a_number, b_number, source_ip))
        })
    });
    
    group.finish();
}

/// Benchmark detection window calculations
fn bench_detection_window(c: &mut Criterion) {
    let mut group = c.benchmark_group("detection_window");
    
    for window_secs in [1, 3, 5, 10] {
        group.bench_with_input(
            BenchmarkId::from_parameter(format!("{}s", window_secs)),
            &window_secs,
            |b, &w| {
                b.iter(|| {
                    let window = DetectionWindow::new(black_box(w)).unwrap();
                    black_box(window.seconds())
                })
            }
        );
    }
    group.finish();
}

/// High-throughput simulation benchmark
/// Simulates processing rate to measure theoretical maximum CPS
fn bench_throughput_simulation(c: &mut Criterion) {
    let mut group = c.benchmark_group("throughput");
    group.throughput(Throughput::Elements(1000)); // 1000 calls per iteration
    group.measurement_time(Duration::from_secs(15));
    group.sample_size(50);
    
    group.bench_function("1k_calls_batch", |b| {
        b.iter(|| {
            for i in 0..1000 {
                let suffix = format!("{:04}", i % 10000);
                let a = MSISDN::new(&format!("+23480123{}", suffix)).unwrap();
                let b = MSISDN::new(&format!("+23480987{}", suffix)).unwrap();
                let ip = IPAddress::new("10.0.0.1").unwrap();
                black_box((a, b, ip));
            }
        })
    });
    
    group.finish();
}

criterion_group!(
    benches,
    bench_msisdn_parsing,
    bench_ip_parsing,
    bench_fraud_score,
    bench_call_value_objects,
    bench_detection_window,
    bench_throughput_simulation,
);

criterion_main!(benches);
