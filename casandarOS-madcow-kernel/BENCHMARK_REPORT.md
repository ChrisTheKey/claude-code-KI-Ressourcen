# Benchmark Report — CasandarOS Madcow Gaming Kernel

**Status:** PRE-BUILD (to be completed post-install)  
**Kernel:** linux-6.18.33-casandarOS-madcow-gaming-kernel  
**Date:** 2026-05-26  

## Benchmark Protocol

### Environment Requirements
- CPU: [detect at runtime]
- GPU: [detect at runtime]
- RAM: [detect at runtime]
- Thermal baseline: stable (within 5°C variance)
- No background tasks (set: `systemctl set-default multi-user.target` for testing)
- Shader cache pre-warmed before measurement run

### Frametime Measurement Tools
- Primary: MangoHud (frametime histogram, 1%/0.1% lows)
- Secondary: `perf stat` (context switches, migrations)
- Thermal: `sensors` + CoreCtrl

### Test Workloads
1. **Desktop Responsiveness**: `cyclictest -t1 -p80 -n -i10000` (scheduler latency)
2. **Gaming Frametime**: Proton-based game, 10-minute session at fixed GPU load
3. **Shader Compilation**: First-run shader compilation measurement
4. **Asset Streaming**: Large open-world game, camera pan stress test

## Results Pending Installation

### Pre-Boot Predictions (based on config)
| Metric | Expected Change vs Baseline | Confidence |
|--------|----------------------------|------------|
| Scheduler wake latency | -10-20% | HIGH (BORE+PREEMPT) |
| Frametime variance | -5-15% | MEDIUM (BORE) |
| 1% low FPS | +5-10% | MEDIUM (HZ=1000) |
| Input latency consistency | Improved | HIGH (PREEMPT_FULL) |
| Wine/Proton compat | Improved | HIGH (NTSync) |
| Online game latency | Improved | MEDIUM (BBR) |

## Baseline Data (to be collected)
```
Stock kernel: [uname -r]
BORE kernel:  6.18.33-casandarOS-madcow-gaming-kernel

Test: cyclictest -t1 -p80 -n -i10000 -l10000
Stock avg latency:  [TBD] µs
BORE avg latency:   [TBD] µs
```

## Acceptance Criteria
- Frametime variance: must not WORSEN vs stock by >5%
- 1% lows: must not WORSEN vs stock by >3%
- System stability: no OOM, no lockup in 4-hour test
- All validation checklist items: PASS
