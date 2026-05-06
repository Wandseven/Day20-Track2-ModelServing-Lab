# Reflection — Lab 20 (Personal Report)

> **Đây là báo cáo cá nhân.** Mỗi học viên chạy lab trên laptop của mình, với spec của mình. Số liệu của bạn không so sánh được với bạn cùng lớp — chỉ so sánh **before vs after trên chính máy bạn**. Grade rubric tính theo độ rõ ràng của setup + tuning của bạn, không phải tốc độ tuyệt đối.

---

**Họ Tên:** Nguyễn Tuấn Kiệt

**Cohort:** A20-K1

**Ngày submit:** 2026-05-06

---

## 1. Hardware spec (từ `00-setup/detect-hardware.py`)

> Paste output của `python 00-setup/detect-hardware.py` vào đây, hoặc điền thủ công:

- **OS:** Windows 11 (AMD64)
- **CPU:** Intel/AMD 16 logical cores
- **Cores:** 16 logical
- **CPU extensions:** AVX2 / FMA / F16C
- **RAM:** 16GB
- **Accelerator:** NVIDIA GeForce RTX 3050 Laptop GPU (4GB VRAM)
- **llama.cpp backend đã chọn:** CUDA (via llama-cpp-python)
- **Recommended model tier:** TinyLlama-1.1B

Sử dụng Windows 11 với GPU RTX 3050. Gặp thách thức khi thư viện `llama-cpp-python` không hỗ trợ sẵn flag `--metrics` như yêu cầu. Thay vì cài đặt bộ công cụ build C++ phức tạp trên Windows, tôi đã tự viết một script wrapper Python bổ sung endpoint Prometheus `/metrics` để thu thập dữ liệu token/s và KV-cache usage. Đồng thời cấu hình `git core.longpaths` để xử lý lỗi đường dẫn dài trên Windows.

---

## 2. Track 01 — Quickstart numbers (từ `benchmarks/01-quickstart-results.md`)

> Paste bảng từ `benchmarks/01-quickstart-results.md` xuống đây (auto-generated bởi `python 01-llama-cpp-quickstart/benchmark.py`).

| tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf | 592 | 68 / 73 | 24.6 / 25.0 | 1581 / 1633 / 1638 | 40.7 |
| tinyllama-1.1b-chat-v1.0.Q2_K.gguf | 142 | 113 / 155 | 19.8 / 20.4 | 1019 / 1365 / 1375 | 50.4 |

Q4_K_M cho tốc độ rất tốt (40.7 tok/s) trên RTX 3050. Q2_K nhanh hơn khoảng 24% nhưng chất lượng text thấp hơn rõ rệt. Với 4GB VRAM, bản Q4 là lựa chọn tối ưu nhất cho sự cân bằng giữa tốc độ và chất lượng.

---

## 3. Track 02 — llama-server load test

> Chạy 2 lần locust ở concurrency 10 và 50, paste tóm tắt bên dưới.

| 10 | 0.41 | ~18000 | 29000 | 29000 | 0 |
| 50 | 0.45 | ~23000 | 36000 | 40000 | 0 |

**KV-cache observation** (từ `record-metrics.py`): peak `llamacpp:kv_cache_usage_ratio` ở concurrency 50 = _0.05_, nghĩa là Model TinyLlama 1.1B chiếm rất ít bộ nhớ cache trên GPU 4GB, cho phép phục vụ nhiều người dùng song song mà không lo tràn VRAM. Bottleneck chủ yếu nằm ở compute của GPU khi xử lý nhiều luồng cùng lúc.

---

## 4. Track 03 — Milestone integration

- **N16 (Cloud/IaC):** stub: localhost process (no Docker)
- **N17 (Data pipeline):** stub: static python dictionary
- **N18 (Lakehouse):** stub: JSON local source
- **N19 (Vector + Feature Store):** stub: in-memory cosine similarity (TOY_DOCS)

**Nơi tốn nhiều ms nhất** trong pipeline (đo bằng `time.perf_counter` trong `pipeline.py`):

- embed: ~100 ms
- retrieve: 0.0 ms
- llama-server: 6004.8 ms

**Reflection** (≤ 60 chữ): Bottleneck nằm hoàn toàn ở llama-server (chiếm 99.9% thời gian). Điều này đúng với kỳ vọng vì việc suy luận LLM (inference) đòi hỏi tài nguyên tính toán cực lớn so với việc tìm kiếm trong một tập dữ liệu nhỏ. Trong thực tế, khi tập dữ liệu lớn hơn, phần retrieve sẽ tăng lên nhưng LLM vẫn là phần nặng nhất.

---

## 5. Bonus — The single change that mattered most

> **Most important section.** Pick **một** thay đổi từ bonus track (build flag, thread sweep, quant pick, GPU offload, KV-cache quantization, speculative decoding, bất cứ challenge nào trong `BONUS-llama-cpp-optimization/CHALLENGES.md`) đã tạo ra speedup lớn nhất trên máy bạn.

**Change:** Điều chỉnh số lượng CPU threads (`n_threads`) để tìm điểm cân bằng tối ưu giữa tính toán và băng thông bộ nhớ.

**Before vs after** (từ kết quả sweep):

```
before (1 thread): 13.82 tok/s
after  (12 threads): 38.44 tok/s
speedup: ~2.78×
```

**Tại sao nó work:**
Việc tăng số thread giúp tận dụng song song hóa các phép toán ma trận trên CPU. Tuy nhiên, tốc độ đạt đỉnh ở 12 threads và giảm xuống ở 16 threads (tổng số cores của máy). Điều này chứng minh rằng `llama.cpp` bị giới hạn bởi băng thông bộ nhớ (memory-bandwidth bound). Khi dùng toàn bộ 16 logical cores, các lõi ảo bắt đầu tranh giành tài nguyên và gây ra độ trễ điều phối (overhead), dẫn đến việc thêm cores không còn mang lại hiệu quả mà ngược lại còn làm giảm hiệu năng tổng thể.

---

## 6. (Optional) Điều ngạc nhiên nhất

Điều ngạc nhiên nhất là việc cài đặt `/metrics` cho server Python không có sẵn, nhưng bằng cách viết một wrapper đơn giản, chúng ta vẫn có thể quan sát được các chỉ số vận hành của Model theo chuẩn Prometheus mà không cần build bản native phức tạp.

---

## 7. Self-graded checklist

- [ ] `hardware.json` đã commit
- [ ] `models/active.json` đã commit (hoặc paste path snapshot vào section 1)
- [ ] `benchmarks/01-quickstart-results.md` đã commit
- [ ] `benchmarks/02-server-results.md` (hoặc CSV từ `record-metrics.py`) đã commit
- [ ] `benchmarks/bonus-*.md` đã commit (ít nhất 1 sweep)
- [ ] Ít nhất 6 screenshots trong `submission/screenshots/` (xem `submission/screenshots/README.md`)
- [ ] `make verify` exit 0 (chạy ngay trước khi push)
- [ ] Repo trên GitHub ở chế độ **public**
- [ ] Đã paste public repo URL vào VinUni LMS

---

**Quan trọng:** repo phải **public** đến khi điểm được công bố. Nếu private, grader không xem được → 0 điểm.
