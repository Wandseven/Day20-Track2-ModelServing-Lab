# Track 02 — Server Load Test Results

Results for llama-server (via custom wrapper with metrics) on NVIDIA RTX 3050 Laptop.

| Concurrency | RPS | TTFB P50 (ms) | E2E P95 (ms) | E2E P99 (ms) | Failures |
|:---|:---:|:---:|:---:|:---:|:---:|
| 10 | 0.42 | ~18000 | 23000 | 23000 | 0 |
| 50 | 0.39 | ~23500 | 37000 | 41000 | 0 |

## Observations
- The server remains stable with 0 failures even at 50 concurrent users.
- P95 latency increases significantly at 50 users, indicating queueing effects as the GPU reaches its compute limit.
- KV-cache usage remains low (5%) for this 1.1B model.
