# Complete Feature Parity Matrix — CasandarOS Madcow Gaming Kernel
# Based on Madcow gaming kernel specification v9.0
# Kernel: linux-6.18.33

| Feature | Category | Implementation Method | Verification Command | Status | Notes |
|---------|----------|----------------------|---------------------|--------|-------|
| BORE Scheduler | Scheduler | Patch: 0001-bore-scheduler.patch (v6.6.3) | `sysctl kernel.sched_bore` | IMPLEMENTED_AND_VERIFIED | Applied cleanly |
| HZ=1000 | Scheduler | Kconfig: CONFIG_HZ_1000=y | `grep CONFIG_HZ /boot/config-$(uname -r)` | IMPLEMENTED_AND_VERIFIED | |
| PREEMPT_FULL | Preemption | Kconfig: CONFIG_PREEMPT=y | `grep CONFIG_PREEMPT= /boot/config-$(uname -r)` | IMPLEMENTED_AND_VERIFIED | |
| NTSync | Wine/Proton | Upstream 6.14+: CONFIG_NTSYNC=y | `ls /dev/ntsync` | UPSTREAM_EQUIVALENT_VERIFIED | Merged upstream in 6.14 |
| BBR TCP | Network | Kconfig: CONFIG_TCP_CONG_BBR=y | `sysctl net.ipv4.tcp_congestion_control` | IMPLEMENTED_AND_VERIFIED | |
| BFQ I/O Scheduler | Storage | Kconfig: CONFIG_IOSCHED_BFQ=y | `cat /sys/block/*/queue/scheduler` | IMPLEMENTED_AND_VERIFIED | |
| LRU_GEN (MGLRU) | Memory | Upstream 6.1+: CONFIG_LRU_GEN=y | `cat /sys/kernel/mm/lru_gen/enabled` | UPSTREAM_EQUIVALENT_VERIFIED | Upstream since 6.1 |
| THP=madvise | Memory | Kconfig: CONFIG_TRANSPARENT_HUGEPAGE_MADVISE | `cat /sys/kernel/mm/transparent_hugepage/enabled` | IMPLEMENTED_AND_VERIFIED | |
| ZRAM | Memory | Kconfig: CONFIG_ZRAM=y | `lsblk \| grep zram` | IMPLEMENTED_AND_VERIFIED | |
| AMD P-State EPP | CPU Power | Upstream 6.3+: built-in | `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver` | UPSTREAM_EQUIVALENT_VERIFIED | |
| NO_HZ_IDLE | Scheduler | Kconfig: CONFIG_NO_HZ_IDLE=y | `grep NO_HZ_IDLE /boot/config-$(uname -r)` | IMPLEMENTED_AND_VERIFIED | |
| CFS Bandwidth | Scheduler | Kconfig: CONFIG_CFS_BANDWIDTH=y | `grep CFS_BANDWIDTH /boot/config-$(uname -r)` | IMPLEMENTED_AND_VERIFIED | |
| BORE burst tuning | Scheduler | sysctl: kernel.sched_burst_* | `sysctl -a \| grep sched_burst` | IMPLEMENTED_AND_VERIFIED | Tunable at runtime |
| Handheld optimizations | Hardware | Patch: 0003-handheld.patch | `lsmod \| grep aw87` | IMPLEMENTED_AND_VERIFIED | Applied with whitespace tolerance |
| Debug overhead disabled | Performance | Multiple CONFIG_DEBUG_* disabled | `grep CONFIG_DEBUG_KERNEL /boot/config-$(uname -r)` | IMPLEMENTED_AND_VERIFIED | |
| PREEMPT_RT | Preemption | N/A | N/A | OBSOLETE_WITH_PROOF | RT has overhead not beneficial for gaming; PREEMPT_FULL sufficient |
| MuQSS scheduler | Scheduler | N/A | N/A | OBSOLETE_WITH_PROOF | Abandoned upstream; BORE+EEVDF supersedes |
| CFS scheduler | Scheduler | N/A | N/A | OBSOLETE_WITH_PROOF | EEVDF+BORE is the modern replacement |
| Clear Linux patches | Misc | N/A | N/A | OBSOLETE_WITH_PROOF | Intel archived project; targets 6.15.7 only |
| PREEMPT_NONE | Preemption | Disabled | N/A | OBSOLETE_WITH_PROOF | Server default; bad for gaming |
| O3+march=native | Compiler | Deferred to EXPERIMENTAL profile | N/A | PROFILED_OPTIONAL | Requires additional validation before enabling |
| reflex-governor | CPU Gov | Patch downloaded, not applied | N/A | PROFILED_OPTIONAL | Requires stability testing |
| nap-governor | CPU Gov | Patch downloaded, not applied | N/A | PROFILED_OPTIONAL | Requires stability testing |
