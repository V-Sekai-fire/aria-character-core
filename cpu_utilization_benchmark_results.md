# CPU Utilization Flow Benchmark Results

## Executive Summary

This benchmark analyzed CPU utilization patterns across different Flow-based convergence approaches to understand multi-core utilization effectiveness. The results reveal significant insights about Flow's behavior and the trade-offs between throughput and CPU utilization.

## System Configuration

- **Available CPU cores:** 12
- **Erlang schedulers:** 12 (with 24 total schedulers including dirty schedulers)
- **Test dataset:** 10,000 activities
- **Benchmark date:** June 19, 2025

## Performance Results

### Throughput Performance (Best to Worst)

| Approach | Time (ms) | Throughput (K activities/sec) | Avg CPU Util |
|----------|-----------|-------------------------------|--------------|
| **Hybrid Flow** | 16 | **625.0K** | 1% |
| Pipeline Flow | 19 | 526.3K | 1% |
| Streaming Flow | 28 | 357.1K | 1% |
| Adaptive Flow | 28 | 357.1K | 1% |
| Baseline Flow | 48 | 208.3K | 1% |
| Hybrid Partition-Aware | 2073 | 4.8K | 0% |
| Load-Balanced Partition | 2136 | 4.7K | 0% |
| Resource-Aware Partition | 6064 | 1.6K | 0% |

## Key Findings

### 1. Throughput vs CPU Utilization Paradox

**Surprising Discovery:** The fastest approaches (Hybrid Flow at 625K activities/sec) show the **lowest** CPU utilization (1%), while the partition-aware approaches that were designed to maximize CPU usage show much lower throughput.

**Analysis:** This suggests that:
- High-throughput Flow approaches are **I/O bound** or use very efficient processing
- Adding CPU-intensive work (like the `:timer.sleep` calls in partition-aware approaches) actually **reduces** overall throughput
- The original Flow implementations are already well-optimized for this type of workload

### 2. Partition-Aware Approaches Trade Throughput for CPU Work

The partition-aware implementations successfully distributed work across more schedulers but at a significant cost:

- **Resource-Aware Partition:** 6064ms (39x slower than Hybrid Flow)
- **Load-Balanced Partition:** 2136ms (13x slower than Hybrid Flow)  
- **Hybrid Partition-Aware:** 2073ms (13x slower than Hybrid Flow)

**Root Cause:** The artificial CPU work (`:timer.sleep` calls) was intended to simulate realistic processing but instead became a bottleneck.

### 3. Scheduler Distribution Patterns

**High-Throughput Approaches:**
- Concentrate work on 3-4 schedulers (typically schedulers 9-12)
- Show 40-70% utilization on active schedulers
- Most schedulers remain at 0% utilization

**Partition-Aware Approaches:**
- Successfully distribute work across more schedulers (6-8 active)
- Show lower per-scheduler utilization (1-2% each)
- Achieve better load distribution but lower overall performance

### 4. Flow's Natural Optimization

The benchmark reveals that Flow's default behavior is already well-optimized:
- **Hybrid Flow** achieves the best balance of speed and resource usage
- **Pipeline Flow** shows excellent throughput with good scheduler utilization
- Default Flow partitioning appears to be more effective than custom partitioning for this workload

## Technical Insights

### Why Partition-Aware Approaches Are Slower

1. **Artificial CPU Work:** The `:timer.sleep` calls simulate realistic processing but create unnecessary delays
2. **Partition Overhead:** Custom partitioning adds coordination overhead
3. **Work Distribution:** Spreading work across more cores doesn't help when the work is artificially delayed

### Why High-Throughput Approaches Work Well

1. **Minimal Processing:** Simple transformations and accumulations are very fast
2. **Efficient Scheduling:** Flow's default scheduling is optimized for this pattern
3. **Memory-Bound Operations:** The workload is likely limited by memory access, not CPU computation

## Recommendations

### For Production Use

1. **Use Hybrid Flow** for maximum throughput on similar workloads
2. **Avoid artificial CPU work** unless it represents real computational requirements
3. **Trust Flow's default partitioning** for most use cases
4. **Monitor actual CPU utilization** - low utilization may indicate optimal efficiency, not poor performance

### For CPU-Intensive Workloads

1. **Replace `:timer.sleep` with actual computational work** (mathematical operations, data transformations)
2. **Use partition-aware approaches only when** the work is genuinely CPU-bound
3. **Benchmark with realistic workloads** rather than artificial delays

### For Further Investigation

1. **Test with real computational work** (matrix operations, string processing, etc.)
2. **Measure memory usage patterns** alongside CPU utilization
3. **Compare with Task-based parallelization** for CPU-intensive operations
4. **Analyze scheduler queue depths** to understand bottlenecks

## Conclusion

This benchmark demonstrates that **higher CPU utilization does not necessarily correlate with better performance**. Flow's high-throughput approaches achieve excellent performance with low CPU utilization, suggesting they are well-optimized for the workload characteristics.

The partition-aware approaches successfully demonstrate multi-core distribution but reveal the importance of having genuinely CPU-intensive work to benefit from such distribution. For workloads that are primarily I/O-bound or memory-bound, Flow's default behavior appears to be optimal.

**Key Takeaway:** Optimize for the actual bottleneck in your workload, not for maximum CPU utilization. Sometimes the most efficient solution uses the least CPU.
