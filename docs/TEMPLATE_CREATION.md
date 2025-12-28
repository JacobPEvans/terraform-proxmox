# Creating Ubuntu Cloud-Init Template for Proxmox

## Overview

This guide creates a reusable Ubuntu 24.04.2 LTS template (VM ID 9001) optimized for Terraform deployment with cloud-init.

## Quick Start

```bash
# SSH to Proxmox host
ssh root@pve.your-domain

# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img

# Create VM
qm create 9001 \
  --name ubuntu-24.04-cloudimg \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9001 ubuntu-24.04-server-cloudimg-amd64.img local-zfs

# Attach disk
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9001-disk-0

# Add cloud-init drive
qm set 9001 --ide2 local-zfs:cloudinit

# Set boot disk
qm set 9001 --boot c --bootdisk scsi0

# Enable qemu-guest-agent
qm set 9001 --agent enabled=1

# Add serial console
qm set 9001 --serial0 socket --vga serial0

# Convert to template
qm template 9001
```

## Detailed Steps

### 1. Download Ubuntu Cloud Image

Ubuntu provides pre-built cloud images optimized for cloud-init:

```bash
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img
```

**Why cloud images?**
- Pre-installed cloud-init and qemu-guest-agent
- Optimized for virtual environments
- Small size (~600MB)
- Official Ubuntu builds

### 2. Create Template VM

```bash
# Create VM with basic config
qm create 9001 \
  --name ubuntu-24.04-cloudimg \
  --description "Ubuntu 24.04.2 LTS Cloud-Init Template" \
  --memory 2048 \
  --cores 2 \
  --cpu x86-64-v2-AES \
  --net0 virtio,bridge=vmbr0
```

### 3. Import and Attach Disk

```bash
# Import cloud image as disk
qm importdisk 9001 ubuntu-24.04-server-cloudimg-amd64.img local-zfs

# Attach as scsi0 with virtio controller
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9001-disk-0

# Enable discard and iothread for SSD performance
qm set 9001 --scsi0 local-zfs:vm-9001-disk-0,discard=on,iothread=1
```

### 4. Configure Cloud-Init

```bash
# Add cloud-init drive (stores user-data/network-config)
qm set 9001 --ide2 local-zfs:cloudinit

# Set boot order
qm set 9001 --boot c --bootdisk scsi0

# Enable qemu-guest-agent for Proxmox integration
qm set 9001 --agent enabled=1

# Add serial console for cloud-init output
qm set 9001 --serial0 socket --vga serial0
```

### 5. Convert to Template

```bash
# Convert VM to template (makes it read-only)
qm template 9001
```

## Update Terraform Configuration

Update `terraform.tfvars`:

```hcl
vms = {
  "splunk-idx1" = {
    # ... other config ...

    clone_template = {
      template_id = 9001  # Use new template
    }

    # Remove cdrom_file_id line
  }
}
```

## Template Maintenance

### Update Template (Quarterly or as needed)

```bash
# Clone template to regular VM
qm clone 9001 9999 --name ubuntu-update-temp

# Start and update
qm start 9999
# SSH in and run updates
ssh ubuntu@vm-ip
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo cloud-init clean
sudo poweroff

# Convert updated VM to new template
qm template 9999

# Update Terraform to use 9999, test deployment
# After validation, delete old template and rename
qm destroy 9001
qm set 9999 --name ubuntu-24.04-cloudimg
# Update VM ID if needed
```

### Create New Version Template

When Ubuntu 24.04.3 releases:

```bash
# Download new cloud image
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img \
  -O ubuntu-24.04.3-cloudimg.img

# Create template 9002
qm create 9002 --name ubuntu-24.04.3-cloudimg ...
# Follow steps above

# Update Terraform to template_id = 9002
# Test deployment
# Archive old template 9001 when confident
```

## Verification

Test the template works:

```bash
# Create test VM from template
qm clone 9001 999 --name test-clone

# Configure cloud-init
qm set 999 --ciuser ubuntu --cipassword test123 --sshkeys ~/.ssh/authorized_keys
qm set 999 --ipconfig0 ip=10.0.1.99/32,gw=10.0.1.1

# Start and verify
qm start 999
ssh ubuntu@10.0.1.99

# Cleanup
qm stop 999
qm destroy 999
```

## Terraform Integration

The VM module automatically uses cloud-init when cloning from templates:

```hcl
clone_template = {
  template_id = 9001
}

ip_config = {
  ipv4_address = "10.0.1.100/32"
  ipv4_gateway = "10.0.1.1"
}

user_account = {
  username = "ubuntu"
  password = "your-secure-password"
  keys     = [file("~/.ssh/id_rsa_vm.pub")]
}
```

Cloud-init applies:
- Network configuration (static IP)
- User account creation
- SSH key installation
- Hostname configuration

## Troubleshooting

**VM won't boot after cloning:**
- Check boot order: `qm config 9001 | grep boot`
- Verify disk attached: `qm config 9001 | grep scsi0`

**Cloud-init not applying configuration:**
- Check cloud-init drive exists: `qm config 9001 | grep ide2`
- View cloud-init logs: `journalctl -u cloud-init`

**Network not configured:**
- Verify DHCP available on vmbr0 during first boot
- Check cloud-init network config: `cat /etc/netplan/50-cloud-init.yaml`

## References

- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- [Proxmox Cloud-Init Support](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
