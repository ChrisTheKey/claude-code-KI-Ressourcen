# Kconfig Rationale — CasandarOS Madcow Gaming Kernel

## HZ=1000

Default Linux is HZ=250 (4ms ticks). Gaming requires sub-4ms scheduling decisions.
At HZ=1000, the scheduler runs every 1ms — critical for consistent frametimes.
Cost: ~0.1% extra CPU overhead (negligible on modern hardware).

## PREEMPT_FULL (vs VOLUNTARY or NONE)

PREEMPT_FULL allows the kernel to preempt ANY code path that isn't holding a spinlock.
This is the single most important setting for gaming latency.
- PREEMPT_NONE: Worst for latency (server default)
- PREEMPT_VOLUNTARY: Intermediate (desktop default)
- PREEMPT_FULL: Best for interactive use — kernel code preemptible at will

## BORE Scheduler

Standard EEVDF (Even Earlier Virtual Deadline First) is latency-fair but doesn't
distinguish between burst (games/UI) and steady (background compile) workloads.
BORE adds a "burst credit" system: tasks that consume their CPU time in short bursts
(like game loops) get scheduling priority boosts. This is exactly what gaming needs.

## NTSync (NT Synchronization)

Wine and Proton translate Windows sync primitives (Mutexes, Events, Semaphores) to
Linux futexes. NTSync provides native kernel support, eliminating the translation
overhead. Merged upstream in Linux 6.14. Critical for modern game compatibility.

## LRU_GEN (Multi-Generation LRU)

Traditional LRU has a 2-list structure (active/inactive). MGLRU adds temporal
awareness — memory used recently stays hot, memory not touched in multiple
generations gets evicted first. Reduces gaming stutter caused by page reclaim.

## NO_HZ_IDLE (vs NO_HZ_FULL)

NO_HZ_IDLE: Disable scheduler tick when CPU is idle — saves power, no latency impact.
NO_HZ_FULL: Disable tick on ALL CPUs — reduces jitter but requires careful CPU
isolation setup. Not recommended for desktop gaming without explicit CPU pinning.
We use NO_HZ_IDLE only.

## BFQ I/O Scheduler

BFQ (Budget Fair Queueing) provides fair I/O bandwidth and low latency for
interactive workloads. Better than CFQ for gaming because it prevents a background
game update from blocking foreground game asset loading.

## Disabled: DEBUG_* options

Debug options add 10-30% overhead to kernel operations. All debug, tracing,
sanitizer, and lock-verification options are disabled. This is a production gaming
kernel, not a development kernel.

## -O3 + march=native

The kernel is typically built with -O2. Gaming kernels benefit from -O3 which
enables additional loop unrolling and vectorization. march=native targets the
exact CPU instruction set of the build machine.
WARNING: march=native binaries are NOT portable to other CPUs.
This kernel is built for the CasandarOS installation machine only.
