# Packer Templates for Proxmox

This directory contains Packer templates for building VM templates on Proxmox VE.

## Splunk Enterprise Template

The `splunk.pkr.hcl` template builds a Splunk Enterprise All-in-One template (VM ID 9200) by cloning
the Debian 12 base template (VM ID 9000) and installing Splunk.

### Critical Hardware Configuration

**IMPORTANT**: The following hardware settings are critical to prevent system freezes and instability:

#### CPU Type: `host`

```hcl
cpu_type = "host"
```

**Why**: Exposes all host CPU features to the VM with **zero CPU emulation overhead**. This provides
maximum stability and performance for single-node homelab use. The default `kvm64` type causes:

- TSC (Time Stamp Counter) clock instability
- High CPU emulation overhead
- System freezes during VM clone/start operations

**Single-Node Design**: All VMs in this homelab use `cpu_type = "host"` (both Packer and Terraform)
for maximum stability. VMs will only run on identical/similar CPUs, which is acceptable for homelab use.

#### SCSI Controller: `virtio-scsi-pci`

```hcl
scsihw = "virtio-scsi-pci"
```

**Why**: Modern, high-performance SCSI controller with low CPU overhead. The default `lsi` (LSI Logic)
controller is:

- Ancient technology (~2003)
- Adds significant CPU overhead during disk I/O
- Causes performance degradation during clone operations

#### OS Type: `l26`

```hcl
os_type = "l26"
```

**Why**: Optimizes VM for Linux 2.6+ kernel instead of generic "other" type.

### Variable Sources

Variables are injected from two sources:

1. **Doppler Secrets** (via `PKR_VAR_*` environment variables):
   - `PROXMOX_VE_ENDPOINT` - API URL
   - `PKR_PVE_USERNAME` - Proxmox username with token ID (`user@realm!tokenid`)
   - `PROXMOX_TOKEN` - API token secret
   - `PROXMOX_VE_NODE` - Node name
   - `PROXMOX_VE_HOSTNAME` - Hostname for SSH
   - `SPLUNK_ADMIN_PASSWORD` - Splunk admin password
   - `SPLUNK_DOWNLOAD_SHA512` - Package checksum

2. **Committed Config File** (`variables.pkrvars.hcl`):
   - Splunk version and build number
   - Architecture (amd64/arm64)
   - Installation paths

### Building Templates

```bash
# Initialize Packer plugins
./packer-build.sh init

# Validate configuration
./packer-build.sh validate

# Build template
./packer-build.sh build
```

The build script automatically validates Doppler secrets and injects them as environment variables.

### Terraform Integration

VMs cloned from this template use the BPG Proxmox provider in Terraform with identical hardware settings:

- **CPU Type**: `cpu_type = "host"` (maximum stability, zero emulation overhead)
- **SCSI Controller**: `virtio-scsi-pci` (modern, high-performance)
- **OS Type**: `l26` (Linux 2.6+ kernel)

All VMs in this single-node homelab use these settings for consistent, stable performance.

## References

- [Packer Proxmox Plugin](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/clone)
- [Packer CPU Type Bug #307](https://github.com/hashicorp/packer-plugin-proxmox/issues/307)
- [Proxmox CPU Types Discussion](https://forum.proxmox.com/threads/cpu-type-host-vs-kvm64.111165/)
