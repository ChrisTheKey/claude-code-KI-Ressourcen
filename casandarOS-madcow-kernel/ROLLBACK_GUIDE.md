# Rollback Guide — CasandarOS Madcow Gaming Kernel

## CRITICAL: Never auto-install. Always verify before deploying.

## If the new kernel fails to boot

### Method 1: GRUB Boot Menu (most common)
1. At boot, press `ESC` or `SHIFT` to enter GRUB menu
2. Select "Advanced options for CachyOS"
3. Choose the previous working kernel (e.g., `linux-cachyos`)
4. Boot and verify system is stable

### Method 2: Arch Live USB
1. Boot Arch live USB
2. Mount your root partition: `mount /dev/sdX /mnt`
3. Chroot: `arch-chroot /mnt`
4. Remove the broken kernel: `pacman -R linux-casandarOS-madcow-gaming-kernel`
5. Reinstall default: `pacman -S linux-cachyos`
6. Regenerate initramfs: `mkinitcpio -P`
7. Update bootloader: `grub-mkconfig -o /boot/grub/grub.cfg`

## Kernel Package Location
All kernel artifacts: `~/casandar_kernel_lab/artifacts/`
Previous config: `~/casandar_kernel_lab/configs/madcow-gaming.config`
Build log: `~/casandar_kernel_lab/logs/build.log`

## DO NOT delete ~/casandar_kernel_lab/
This directory contains all build artifacts, patches, and reproducibility data.

## Emergency Sysctl Reset
If system is unstable but booted, reset all custom sysctl:
```bash
sysctl --system  # reload defaults
```

## Kernel Removal
```bash
# Remove kernel package (when installed via pacman)
sudo pacman -R linux-casandarOS-madcow-gaming-kernel linux-casandarOS-madcow-gaming-kernel-headers

# Or manually:
sudo rm /boot/vmlinuz-casandarOS-madcow-gaming-kernel
sudo rm /boot/initramfs-casandarOS-madcow-gaming-kernel.img
sudo rm -rf /lib/modules/6.18.33-casandarOS-madcow-gaming-kernel
sudo grub-mkconfig -o /boot/grub/grub.cfg
```
