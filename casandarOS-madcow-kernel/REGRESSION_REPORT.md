# Regression Report — CasandarOS Madcow Gaming Kernel

**Status:** PRE-BOOT  
**Kernel:** linux-6.18.33-casandarOS-madcow-gaming-kernel

## Regression Classification System

### Class A — Blocking Regressions (must fix before release)
- System fails to boot
- Random kernel panics or lockups
- GPU reset loops
- OOM in normal gaming workload
- NTSync device missing
- Frametime variance worsens >10% vs stock

### Class B — Notable Regressions (require investigation)
- 1% lows drop >5% vs stock
- Scheduler wake latency increases >10%
- Higher CPU usage at same workload
- Long-session degradation detected

### Class C — Minor Regressions (log and monitor)
- Marginal throughput changes (<5%)
- Cosmetic kernel message differences
- Non-impactful driver behavior changes

## Known Upstream Changes in 6.18 vs Previous Madcow

| Area | Change | Gaming Impact | Status |
|------|--------|---------------|--------|
| EEVDF scheduler | Continued refinement | Positive | MONITOR |
| NTSync | Fully upstream | Positive | VERIFIED |
| AMD P-State EPP | Improvements | Positive | MONITOR |
| AMDGPU | New ring scheduling | TBD | MONITOR |
| LRU_GEN | Stability improvements | Positive | VERIFIED |
| futex | Minor bug fixes | Neutral | VERIFIED |

## Regression Test Procedure
1. Boot new kernel
2. Run validation checklist (VALIDATION_GUIDE.md)
3. Run `cyclictest` — compare vs stock baseline
4. 4-hour gaming session with MangoHud
5. Compare frametime histograms
6. Check thermal behavior
7. Classify any regressions per system above

## Regression Log
[Empty — to be filled post-boot]
