# Kernel Panic Investigation - VM 200 Splunk

**Date:** January 8, 2026
**Event:** Kernel panic when attempting to shut down VM 200 and start VM 9201

## Summary

A kernel panic occurred with the message **"KERNEL PANIC! Please reboot your computer. Fatal exception in interrupt"** when shutting down Splunk VM 200 to test clone VM 9201. Investigation revealed **ZFS data corruption caused by CPU/RAM overclocking** combined with intensive disk I/O operations.

## Root Cause

**Primary:** CPU and RAM were overclocked in BIOS settings
**Secondary:** Overclocking caused memory bit flips during ZFS operations
**Trigger:** Shutting down VM 200 caused disk detach operations that attempted to read corrupted ZFS data

## Technical Details

### Kernel Panic Message
```
KERNEL PANIC! Please reboot your computer.
Fatal exception in interrupt
```

**"Fatal exception in interrupt"** means:
- Kernel was handling a hardware interrupt (disk I/O)
- Critical error occurred in the interrupt handler
- Kernel detected unsafe state and halted to prevent data corruption

### ZFS Data Corruption

Corrupted file identified:
```bash
zpool status -v rpool
# Output:
errors: Permanent errors have been detected in the following files:
        rpool/data/vm-200-disk-0:<0x1>
```

VM 200's boot disk has **permanent ZFS checksum errors** from corrupted blocks.

### Evidence from Logs

**Last known good operations (Jan 8, 18:23:58):**
```
Jan 08 18:23:58 pve pvedaemon[60031]: stop VM 200: UPID:pve:0000EA7F:000A9C68:695FF63E:qmstop:200:root@pam:
Jan 08 18:23:59 pve pvedaemon[1835]: <root@pam> end task UPID:pve:0000EA7F:000A9C68:695FF63E:qmstop:200:root@pam: OK
```

**VM 9201 start attempt (Jan 08, 18:24:02):**
```
Jan 08 18:24:02 pve pvedaemon[60128]: start VM 9201: UPID:pve:0000EAE0:000A9DDE:695FF642:qmstart:9201:root@pam:
Jan 08 18:24:03 pve kernel: tap9201i0: entered promiscuous mode
Jan 08 18:24:03 pve kernel: vmbr0: port 10(tap9201i0) entered forwarding state
```

**Logs end abruptly** - system crashed immediately after VM 9201 network setup, likely during disk attachment when corrupted ZFS data was read.

### Additional System Warnings

**AMD Zen1 DIV0 Bug:**
```
[    0.148117] AMD Zen1 DIV0 bug detected. Disable SMT for full protection.
```

This CPU bug combined with overclocking increases instability risk.

**ZFS Errors During Boot:**
```
Jan 08 16:37:47 pve zed[9864]: eid=11 class=data pool='rpool' priority=0 err=52 flags=0x8081
Jan 08 16:37:47 pve zed[9866]: eid=12 class=checksum pool='rpool' vdev=nvme-eui.002538545142628c-part3 algorithm=fletcher4 size=16384 offset=3557686005760
```

ZFS detected checksum errors on the NVMe drive at specific offset.

## Timeline

| Time | Event |
|------|-------|
| Unknown | CPU/RAM overclocked in BIOS |
| Ongoing | Memory bit flips causing ZFS corruption |
| 16:28 | System rebooted (first reboot after Proxmox 9.1 upgrade) |
| 18:23:58 | Attempted to stop VM 200 - succeeded |
| 18:24:02 | Attempted to start VM 9201 |
| 18:24:03 | **Kernel panic** - system froze |
| ~18:26 | Physical reboot, BIOS reset to defaults |
| 19:26 | System back online at stock speeds |

## Resolution

### Immediate Actions Taken

1. **BIOS reset to defaults:**
   - Removed all CPU overclock settings
   - Removed all RAM overclock settings
   - Kept SVM virtualization enabled

2. **System restarted at stock speeds**

3. **ZFS corruption identified:**
   ```bash
   zpool status -v rpool
   # Shows: rpool/data/vm-200-disk-0:<0x1> corrupted
   ```

### Recovery Plan

1. **Destroy corrupted VM 200 completely**
   - Cannot trust any data on corrupted disk
   - ZFS detected permanent errors

2. **Disable all container autostarts**
   - Eliminate 11 containers as crash variables
   - Reduce memory/I/O pressure

3. **Strip all VM configs to bare minimum**
   - Remove QEMU guest agent (known to cause hangs)
   - Remove cloud-init if not essential
   - Remove all optional devices
   - Test with absolute minimal configuration

4. **Recreate VM 200 from template 9200**
   - Fresh disk, no corruption
   - Bare minimum configuration
   - Test stability before adding complexity

## Lessons Learned

### Overclocking and Virtualization Don't Mix

**Problem:** Overclocking introduces instability that's amplified under virtualization workloads:
- Memory bit flips corrupt VM disk images
- ZFS detects corruption but data is already damaged
- Kernel panics occur when corrupted data is accessed

**Solution:** Run Proxmox hosts at **stock CPU and RAM speeds**. Virtualization already maximizes hardware utilization - overclocking adds risk without meaningful benefit.

### ZFS Checksums Save Data

ZFS's end-to-end checksumming detected the corruption and prevented silent data corruption from spreading. Without ZFS, the corrupted data would have been silently written and read, causing unpredictable VM behavior.

### AMD Zen1 DIV0 Bug

The AMD Zen1 DIV0 bug warning suggests SMT (Simultaneous Multithreading) should be disabled for "full protection". Combined with overclocking, this creates additional instability.

**Recommendation:** Consider disabling SMT in BIOS if stability issues persist even at stock speeds.

### Kernel 6.17.4-2-pve Stability

This is a very new kernel (January 2026). If issues persist after removing overclocking and simplifying configs, consider using the older 6.8.12-17-pve kernel that was previously stable.

## Preventive Measures

1. **No overclocking on Proxmox hosts** - ever
2. **Regular ZFS scrubs** - detect corruption early
3. **Enable ZFS email notifications** for pool errors
4. **Minimal VM configurations** - reduce complexity
5. **Incremental changes** - test one thing at a time
6. **Memory testing** - run memtest86+ if instability continues

## Related Files

- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - General troubleshooting guide
- [PROXMOX_UPGRADE.md](./PROXMOX_UPGRADE.md) - Upgrade procedures and issues

## References

- [ZFS Error Messages](https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-8A)
- [Proxmox VE Kernel Parameters](https://pve.proxmox.com/wiki/Linux_Container#pct_settings)
- [AMD Zen DIV0 Bug](https://www.kernel.org/doc/html/latest/x86/amd-memory-encryption.html)
