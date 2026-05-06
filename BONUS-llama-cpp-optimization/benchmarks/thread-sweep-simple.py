import time
import json
import os
from llama_cpp import Llama

def benchmark_threads():
    model_path = ""
    try:
        with open("models/active.json", "r") as f:
            model_path = json.load(f).get("primary_model")
    except:
        print("ERROR: active.json not found")
        return

    if not os.path.exists(model_path):
        print(f"ERROR: Model {model_path} not found")
        return

    results = []
    # Test different thread counts
    thread_counts = [1, 2, 4, 8, 12, 16]
    
    print(f"==> Starting Thread Sweep on {model_path}")
    print(f"| Threads | Load Time (s) | Speed (tok/s) |")
    print(f"|---------|---------------|---------------|")

    for t in thread_counts:
        start_load = time.time()
        # Initialize model with t threads and CUDA offloading (n_gpu_layers=99)
        llm = Llama(model_path=model_path, n_threads=t, n_gpu_layers=99, verbose=False, n_ctx=512)
        load_time = time.time() - start_load
        
        # Simple generation to measure speed
        prompt = "Explain quantum physics in one paragraph."
        start_gen = time.time()
        output = llm(prompt, max_tokens=100)
        gen_time = time.time() - start_gen
        
        tokens = output['usage']['completion_tokens']
        tok_per_sec = tokens / gen_time
        
        print(f"| {t:7} | {load_time:13.2f} | {tok_per_sec:13.2f} |")
        results.append({"threads": t, "load_time": load_time, "speed": tok_per_sec})
        
        # Free memory
        del llm

    # Save results
    os.makedirs("benchmarks", exist_ok=True)
    with open("benchmarks/bonus-thread-sweep.json", "w") as f:
        json.dump(results, f, indent=2)
    
    print(f"\n==> Done! Results saved to benchmarks/bonus-thread-sweep.json")

if __name__ == "__main__":
    benchmark_threads()
