# Patch Interaction Report — CasandarOS Madcow Gaming Kernel

## Applied Patches

### 0001-bore-scheduler.patch
- **Source:** firelzrd/bore-scheduler v6.6.3 for linux-6.18.22
- **Files modified:** include/linux/sched.h, include/linux/sched/bore.h, init/Kconfig, kernel/Kconfig.hz, kernel/exit.c, kernel/fork.c, kernel/futex/waitwake.c, kernel/sched/Makefile, kernel/sched/bore.c, kernel/sched/core.c, kernel/sched/debug.c, kernel/sched/fair.c, kernel/sched/sched.h
- **Apply result:** CLEAN (minor offsets, all hunks succeeded)
- **Interaction risks:** None known — BORE extends EEVDF, does not replace it
- **Upstream conflict risk:** LOW — BORE hooks into well-defined scheduler extension points

### 0003-handheld.patch (CachyOS misc/handheld)
- **Source:** CachyOS/kernel-patches master/6.18/misc/0001-handheld.patch
- **Files modified:** sound/soc/codecs/aw87xxx/* (amplifier driver), max98388.c
- **Apply result:** PARTIAL (2 hunks failed dry-run, applied with -l whitespace tolerance)
- **Gaming relevance:** Handheld gaming device audio codecs (Steam Deck-adjacent hardware)
- **Interaction risks:** Isolated to audio subsystem — no scheduler or MM interaction
- **Upstream conflict risk:** LOW — device-specific driver additions

## Rejected Patches and Reasons

| Patch | Source | Reason | Proof |
|-------|--------|--------|-------|
| 0002-bore-cachy.patch | CachyOS sched/ | Duplicate with 0001-bore-scheduler.patch; 3/25 hunks FAILED | Dry-run output |
| 0005-reflex-governor.patch | CachyOS misc/ | Requires stability validation; PROFILED_OPTIONAL | No runtime evidence yet |
| 0004-nap-governor.patch | CachyOS misc/ | Requires stability validation; PROFILED_OPTIONAL | No runtime evidence yet |
| Clear Linux patches | Intel clearlinux-pkgs | Project discontinued; targets 6.15.7 | HTTP 404 on 6.18 paths |

## Interaction Matrix

| Patch A | Patch B | Interaction | Risk |
|---------|---------|-------------|------|
| bore-scheduler | handheld | None (different subsystems) | NONE |
| bore-scheduler | PREEMPT_FULL | Complementary (both reduce latency) | NONE |
| bore-scheduler | HZ=1000 | Complementary (finer scheduling granularity) | NONE |
| bore-scheduler | LRU_GEN | No interaction | NONE |
| PREEMPT_FULL | HZ=1000 | Complementary | NONE |

## Anti-Snake-Oil Verification
The following were evaluated and REJECTED as placebo/unsupported:
- sysctl spam (random internet "gaming" sysctls without telemetry)
- Disabling ALL c-states (causes thermal instability)
- O3+march=native (deferred — requires validation, not blindly enabled)
- PREEMPT_RT (adds overhead without gaming benefit)
- Maximum boost tables (thermal instability risk)
