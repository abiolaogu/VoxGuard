# Video Training Scripts
## Anti-Call Masking System

### Video 1: System Overview (3 Minutes)
**Target**: All Users
**Visuals**: Slide deck showing "Voice Switch -> Rust -> Database".
**Script**:
> "Hello and welcome. Today we are looking at the Anti-Call Masking System.
> Fraudsters try to hide by changing their phone numbers constantly. This is called Masking.
> Our system catches them by counting how many *different* people call the *same* destination in 5 seconds.
> If that number is too high, we block the call.
> We use Rust for speed, so this happens in less than 1 millisecond."

### Video 2: For SOC Analysts - Handling Alerts (5 Minutes)
**Target**: Security Analysts
**Visuals**: Screen recording of the Alert Dashboard / Log View.
**Script**:
> "In this video, we will walk through a live alert.
> [Show Alert popping up]
> Here we see a 'High Severity' alert.
> Notice the B-Number: +234...
> And look at the A-Numbers list. There are 15 different numbers.
> This pattern confirms a Simbox or Botnet attack.
> Your action is to click 'Block Range' or escalate to the Voice Team."

### Video 3: For DevOps - Infrastructure & Scaling (5 Minutes)
**Target**: Network Admins
**Visuals**: Terminal showing `kubectl` commands.
**Script**:
> "Let's look at how this system scales.
> We typically run 3 replicas of the Detection Service.
> [Run `kubectl get hpa`]
> Here you see the Horizontal Pod Autoscaler.
> As CPU usage hits 70%, Kubernetes automatically adds more pods.
> Data is stored in ClickHouse. Let's query it.
> [Run `clickhouse-client` query]
> This allows us to handle millions of calls without slowing down."
