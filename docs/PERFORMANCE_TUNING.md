# Proxmox Performance Tuning

Configuration guide for memory, swap, and system limits on Proxmox VE.

## ZFS Swap Configuration

For systems with limited RAM but abundant NVMe storage, a large ZFS ZVOL
swap provides memory pressure relief.

### Creating ZFS Swap

```bash
# Create swap ZVOL with optimal settings
zfs create -V 96G -b $(getconf PAGESIZE) \
  -o compression=zle \
  -o sync=disabled \
  -o primarycache=metadata \
  -o secondarycache=none \
  -o logbias=throughput \
  rpool/swap

# Format and enable
mkswap /dev/zvol/rpool/swap
swapon /dev/zvol/rpool/swap

# Add to fstab for persistence
echo "/dev/zvol/rpool/swap none swap sw 0 0" >> /etc/fstab
```

### Settings Explained

| Setting              | Value      | Purpose                            |
| -------------------- | ---------- | ---------------------------------- |
| compression          | zle        | Fast, minimal CPU overhead         |
| sync                 | disabled   | Swap doesn't need sync guarantees  |
| primarycache         | metadata   | Don't cache swap data in ARC       |
| secondarycache       | none       | No L2ARC for swap                  |
| logbias              | throughput | Optimize for sequential I/O        |

## Kernel Memory Settings

Create `/etc/sysctl.d/10-proxmox-tuning.conf`:

```bash
# Swap behavior - lower = prefer RAM (10-30 for SSD/NVMe)
vm.swappiness = 10

# VFS cache pressure - lower = keep directory/inode caches longer
vm.vfs_cache_pressure = 50

# Dirty page writeback - optimized for NVMe
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Memory overcommit - heuristic (default, safe for homelab)
vm.overcommit_memory = 0
```

Apply with: `sysctl --system`

## System Ulimits

Services like Splunk require high file descriptor and process limits.

### PAM Limits

Create `/etc/security/limits.d/90-services.conf`:

```text
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
splunk soft nofile 65536
splunk hard nofile 65536
root soft nofile 65536
root hard nofile 65536
```

### Systemd Default Limits

Create `/etc/systemd/system.conf.d/limits.conf`:

```ini
[Manager]
DefaultLimitNOFILE=65536:65536
DefaultLimitNPROC=65536:65536
```

Apply with: `systemctl daemon-reload`

## ZFS ARC Tuning

The ZFS Adaptive Replacement Cache (ARC) should be sized based on total RAM.

### Recommended ARC Sizes

| Physical RAM | Recommended ARC Max | Command                            |
| ------------ | ------------------- | ---------------------------------- |
| 16 GB        | 2-4 GB              | `echo 4294967296 > ...zfs_arc_max` |
| 32 GB        | 8-16 GB             | `echo 17179869184 > ...zfs_arc_max`|
| 64 GB        | 32-48 GB            | `echo 51539607552 > ...zfs_arc_max`|

### Persistent Configuration

Create `/etc/modprobe.d/zfs.conf`:

```bash
options zfs zfs_arc_max=<ARC_MAX_BYTES>
```

Then regenerate initramfs: `update-initramfs -u`

## Verification Commands

```bash
# Check swap status
swapon --show
free -h

# Check sysctl settings
sysctl vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio

# Check ulimits
bash -c 'ulimit -n'

# Check ZFS ARC
cat /sys/module/zfs/parameters/zfs_arc_max
```

## Related Resources

- [Splunk System Requirements](https://docs.splunk.com/Documentation/Splunk/latest/Installation/Systemrequirements)
- [ZFS on Linux Tuning](https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/index.html)
- [Proxmox Memory Management](https://pve.proxmox.com/wiki/Memory)
