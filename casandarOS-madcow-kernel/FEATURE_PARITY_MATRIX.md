# Feature Parity Matrix — CasandarOS Madcow Gaming Kernel

**Base:** Linux v6.18.33  
**Target:** CachyOS Linux (Arch-based) gaming system  
**Philosophy:** Frametime consistency > raw FPS > average FPS  

## Mandatory Features

| Feature | Status | Source | Notes |
|---------|--------|--------|-------|
| BORE Scheduler | PENDING | firelzrd/bore-scheduler | Core gaming feature |
| PREEMPT_FULL | CONFIG | Kconfig | Full kernel preemption |
| NTSync | UPSTREAM | 6.14+ | Wine/Proton NT sync |
| AMD P-State EPP | UPSTREAM | 6.3+ | AMD freq scaling |
| futex2 | UPSTREAM | 6.x | Fast userspace mutexes |
| ZRAM | CONFIG | Kconfig | Compressed swap |
| BBR TCP | CONFIG | Kconfig | Network latency |
| BFQ I/O scheduler | CONFIG | Kconfig | Storage latency |
| IRQ threading | CONFIG | Kconfig | Interrupt isolation |
| Transparent Hugepages | CONFIG | Kconfig | Memory throughput |

## Gaming-Specific Kconfig Decisions

| Option | Value | Reason |
|--------|-------|--------|
| CONFIG_HZ | 1000 | 1ms scheduler tick for gaming |
| CONFIG_PREEMPT | y | Full preemption |
| CONFIG_NO_HZ_FULL | n | Not beneficial for gaming (introduces jitter) |
| CONFIG_NO_HZ_IDLE | y | Tickless when idle (saves power) |
| CONFIG_CGROUP_SCHED | y | Per-cgroup scheduling control |
| CONFIG_FAIR_GROUP_SCHED | y | Fair scheduling groups |
| CONFIG_SCHED_BORE | y | BORE scheduler extension |
| CONFIG_MQ_IOSCHED_DEADLINE | y | For NVMe |
| CONFIG_IOSCHED_BFQ | y | For HDD/SATA |
| CONFIG_TCP_CONG_BBR | y | BBR congestion control |
| CONFIG_DEFAULT_TCP_CONG | "bbr" | Set as default |
| CONFIG_LRU_GEN | y | Multi-gen LRU (better gaming memory) |
| CONFIG_TRANSPARENT_HUGEPAGE | y | THP enabled |
| CONFIG_TRANSPARENT_HUGEPAGE_MADVISE | y | App-controlled THP |

## Excluded / Disabled Features

| Feature | Reason |
|---------|--------|
| CONFIG_PREEMPT_RT | Full RT has overhead not needed for gaming |
| CONFIG_DEBUG_* | All debug options OFF (performance) |
| CONFIG_KASAN | Memory sanitizer OFF (massive overhead) |
| CONFIG_SLUB_DEBUG | SLUB debug OFF |
| CONFIG_FTRACE | Kernel tracer OFF (use perf instead) |
| CONFIG_LOCKDEP | Lock dependency checker OFF |
| CONFIG_FRAME_POINTER | OFF (use DWARF unwinder instead) |

## Cachy-Specific Tweaks (from CachyOS linux-cachyos PKGBUILD)

| Tweak | Description |
|-------|-------------|
| -O3 optimization | Build with GCC -O3 for native arch |
| march=native | Optimize for host CPU microarch |
| BORE default burst | Tune burst ratio for gaming responsiveness |
| vm.compaction_proactiveness=0 | Disable proactive memory compaction |
| vm.watermark_boost_factor=1 | Reduce memory fragmentation |
| kernel.nmi_watchdog=0 | Disable NMI watchdog |
