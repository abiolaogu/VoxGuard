# Training Manual
## Anti-Call Masking System

### 1. Course Introduction
Welcome to the Anti-Call Masking System training. This course is designed to get you up to speed with the architecture, usage, and maintenance of our fraud detection platform.

**Target Audience**:
*   SOC Analysts
*   DevOps Engineers
*   Software Developers

### 2. Module 1: System Basics
**Goal**: Understand what Call Masking is and how we stop it.

*   **Concept**: Call Masking (CLI Spoofing) is when a fraudster rotates A-numbers to bypass blocking.
*   **The Solution**: We track the *rate* of distinct A-numbers calling a single B-number in a 5-second window.
*   **Key Term**: "Sliding Window" - A time window that moves forward continuously.

### 3. Module 2: The Architecture (For Devs/Ops)
**Goal**: Understand the Rust + ClickHouse stack.

*   **Detection Service**: Written in Rust. It's the "Brain". It checks every call.
*   **DragonflyDB**: The "Memory". It remembers who called whom in the last few seconds.
*   **ClickHouse**: The "Archive". It remembers everything forever.

### 4. Module 3: Hands-On Exercises

#### Exercise A: Simulate an Attack (Analysts)
1.  Open the Dashboard (if available) or view Logs.
2.  Run the attack simulator script: `./scripts/attack_sim.sh`.
3.  Observe the "CRITICAL ALERT" appear in the logs/dashboard.
4.  Identify the B-Number under attack.

#### Exercise B: Deploy Updates (Ops)
1.  Change the `DETECTION_THRESHOLD` in `k8s/configmap.yaml` from 5 to 10.
2.  Apply the change: `kubectl apply -f k8s/configmap.yaml`.
3.  Restart the pods: `kubectl rollout restart deployment/detection-service`.
4.  Verify the new threshold is active.
