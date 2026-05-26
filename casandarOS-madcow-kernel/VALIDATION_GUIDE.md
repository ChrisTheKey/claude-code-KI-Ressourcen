# Validation Guide — CasandarOS Madcow Gaming Kernel

## Post-Install Verification Checklist

### 1. Verify Kernel Version
```bash
uname -r
# Expected: 6.18.33-casandarOS-madcow-gaming-kernel
```

### 2. Verify BORE Scheduler
```bash
cat /sys/kernel/debug/sched/debug | grep -A5 "sched_bore"
sysctl kernel.sched_bore
# Expected: kernel.sched_bore = 1
```

### 3. Verify HZ=1000
```bash
grep CONFIG_HZ /boot/config-$(uname -r)
# Expected: CONFIG_HZ=1000
```

### 4. Verify Full Preemption
```bash
cat /boot/config-$(uname -r) | grep CONFIG_PREEMPT=
# Expected: CONFIG_PREEMPT=y
```

### 5. Verify NTSync (Wine/Proton)
```bash
ls /dev/ntsync
# Expected: /dev/ntsync exists
```

### 6. Verify BBR TCP
```bash
sysctl net.ipv4.tcp_congestion_control
# Expected: net.ipv4.tcp_congestion_control = bbr
```

### 7. Verify THP=madvise
```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
# Expected: always [madvise] never
```

### 8. Verify LRU_GEN
```bash
cat /sys/kernel/mm/lru_gen/enabled
# Expected: 0x0007 (all bits set)
```

### 9. Verify BFQ I/O Scheduler
```bash
cat /sys/block/$(lsblk -d -o NAME | tail -1)/queue/scheduler
# Expected: [...] bfq or [bfq]
```

### 10. Verify ZRAM Active
```bash
lsblk | grep zram
# Expected: zram0 device present
```

## Gaming Performance Validation

### Frametime Tools
```bash
# Mangohud (recommended)
yay -S mangohud
mangohud %command%  # Steam launch option

# Or: gamemode + mangohud
yay -S gamemode lib32-gamemode
```

### Baseline Comparison Procedure
1. Boot stock CachyOS kernel
2. Run game for 10 minutes, record frametimes via Mangohud
3. Note: avg FPS, 1% low, 0.1% low, max frametime spike
4. Reboot into madcow-gaming-kernel
5. Same game, same settings, same duration
6. Compare: frametime variance, 1% lows, spike frequency

### Scheduler Analysis
```bash
# After boot with madcow kernel:
perf sched latency --sort max
perf stat -e context-switches,migrations -a sleep 5
```

## Regression Detection
If any of the following worsen vs stock kernel → REGRESSION:
- 1% lows drop by >5%
- Max frametime spike increases by >2ms
- Scheduler wake latency increases
- System stability degrades (OOM, lockup)

Report regressions to: ~/casandar_kernel_lab/logs/ with full details.
