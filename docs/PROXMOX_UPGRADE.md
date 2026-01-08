# Proxmox VE Upgrade Guide

Documentation of the Proxmox VE 8.4 to 9.1 upgrade process and lessons learned.

## Pre-Upgrade Checklist

1. **Backup everything:**
   - `/etc/pve/` directory (cluster configuration)
   - VM configurations and data
   - Container configurations and data

2. **Check current version:**

   ```bash
   pveversion -v
   ```

3. **Review release notes** for breaking changes

## Upgrade Process

Follow the official [Proxmox VE Upgrade Guide](https://pve.proxmox.com/wiki/Upgrade_from_8_to_9).

## Post-Upgrade Verification

Run the upgrade check tool:

```bash
pve8to9 --full
```

### Common Warnings and Fixes

#### 1. Package Updates Available

**Warning:** `updates for the following packages are available: <package-name>`

**Fix:**

```bash
apt update && apt upgrade -y
```

#### 2. Unnecessary systemd-boot Package

**Warning:** `systemd-boot package installed on legacy-boot system is not necessary`

**Fix:**

```bash
apt remove --purge systemd-boot
```

This only applies to legacy BIOS systems. UEFI systems need systemd-boot.

#### 3. Missing CPU Microcode Package

**Warning:** `The matching CPU microcode package 'amd64-microcode' could not be found`

**Fix:**

1. Add `non-free-firmware` to apt sources:

   ```bash
   # Edit /etc/apt/sources.list.d/debian.sources
   # Change: Components: main contrib
   # To: Components: main contrib non-free-firmware
   ```

2. Install the package:

   ```bash
   apt update
   apt install amd64-microcode  # For AMD CPUs
   # or
   apt install intel-microcode  # For Intel CPUs
   ```

3. Reboot for microcode to take effect

#### 4. Old RRD Metrics Files

**Info:** `Found 'N' RRD files using the old format`

These are historical metrics files. Safe to delete if you don't need old graphs:

```bash
# Location: /var/lib/rrdcached/db/pve2-*
# Delete manually if desired
```

## Certificate Issues After Upgrade

### Hostname Mismatch

After upgrade or hostname changes, certificates may reference old hostnames.

**Symptoms:**

- Browser shows certificate for wrong hostname
- `curl -vk https://pve.example.com:8006/` shows unexpected CN

**Root Cause:**

Certificate was generated with old `/etc/hosts` configuration.

**Fix:**

1. Verify hostname configuration:

   ```bash
   hostname          # Short hostname
   hostname -f       # FQDN
   cat /etc/hosts    # Should have: <IP> <FQDN> <short>
   cat /etc/hostname # Should have short hostname only
   ```

2. Regenerate certificates:

   ```bash
   # For self-signed certs
   pvecm updatecerts --force
   systemctl restart pveproxy

   # For ACME/Let's Encrypt
   pvenode acme cert order --force
   ```

See [ACME.md](./ACME.md) for Let's Encrypt setup details.

## Apt Sources Configuration

Proxmox 9 uses the new deb822 `.sources` format instead of traditional `.list` files.

### File Locations

- `/etc/apt/sources.list.d/debian.sources` - Debian repositories
- `/etc/apt/sources.list.d/proxmox.sources` - Proxmox repositories
- `/etc/apt/sources.list.d/pve-enterprise.sources` - Enterprise repo (subscription)
- `/etc/apt/sources.list.d/ceph.sources` - Ceph repositories (if used)

### Example debian.sources with non-free-firmware

```text
Types: deb
URIs: http://ftp.us.debian.org/debian/
Suites: trixie
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://ftp.us.debian.org/debian/
Suites: trixie-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

## Post-Upgrade Tasks

1. **Clean up old packages:**

   ```bash
   apt autoremove
   ```

2. **Verify all services:**

   ```bash
   systemctl status pveproxy pvedaemon pvescheduler pvestatd
   ```

3. **Test VM and container operations:**
   - Start/stop a VM
   - Access console
   - Verify networking

4. **Update VM machine versions** (if needed):

   ```bash
   # Check VM machine versions
   qm config <vmid> | grep machine
   ```

5. **Schedule a reboot** to apply microcode updates:

   ```bash
   # Microcode is applied at boot
   # Schedule during maintenance window
   shutdown -r +5 "Rebooting for microcode update"
   ```

## References

- [Proxmox VE 9 Release Notes](https://pve.proxmox.com/wiki/Roadmap#Proxmox_VE_9.0)
- [Upgrade from 8 to 9](https://pve.proxmox.com/wiki/Upgrade_from_8_to_9)
- [Certificate Management](https://pve.proxmox.com/wiki/Certificate_Management)
