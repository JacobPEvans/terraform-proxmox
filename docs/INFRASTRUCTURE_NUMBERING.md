# Infrastructure Numbering Scheme

**Status**: Active Production Infrastructure (100% Terraform-managed)

---

## Numbering Conventions

### LXC Containers (100-199)

All services run as lightweight LXC containers, organized by function:

- **100-110**: Infrastructure (Ansible, PVE scripts)
- **150-169**: AI development (Claude Code, Gemini)
- **171-179**: Cribl Stream (log processing)
- **181-189**: Cribl Edge (log forwarding)
- **190-199**: Splunk management

### VMs (200+)

Heavy I/O workloads run as full VMs:

- **200**: Splunk Enterprise all-in-one VM
- **201+**: Reserved for future VMs

---

## Complete Infrastructure Map

### LXC Containers - Infrastructure (100-110)

| ID  | Name              | Type | Cores | RAM  | Storage | Pool           | Purpose                              |
|-----|-------------------|------|-------|------|---------|----------------|--------------------------------------|
| 100 | ansible           | LXC  | 2     | 2GB  | 64GB    | infrastructure | Ansible control node - primary       |
| 101 | ansible-2         | LXC  | 2     | 2GB  | 64GB    | infrastructure | Ansible control node - secondary     |
| 102 | pve-scripts-local | LXC  | 1     | 512MB| 8GB     | infrastructure | Proxmox VE Helper Scripts            |

### LXC Containers - AI Development (150-169)

| ID  | Name           | Type | Cores | RAM  | Storage | Pool | Purpose                              |
|-----|----------------|------|-------|------|---------|------|--------------------------------------|
| 150 | claude-code-01 | LXC  | 2     | 2GB  | 64GB    | ai   | Claude Code development environment 1|
| 151 | claude-code-02 | LXC  | 2     | 2GB  | 64GB    | ai   | Claude Code development environment 2|
| 161 | gemini-01      | LXC  | 2     | 2GB  | 64GB    | ai   | Gemini development environment 1     |
| 162 | gemini-02      | LXC  | 2     | 2GB  | 64GB    | ai   | Gemini development environment 2     |

### LXC Containers - Cribl Stream (171-179)

| ID  | Name           | Type | Cores | RAM  | Storage | Pool    | Purpose                              |
|-----|----------------|------|-------|------|---------|---------|--------------------------------------|
| 171 | cribl-stream-1 | LXC  | 2     | 2GB  | 32GB    | logging | Cribl Stream processing node 1       |
| 172 | cribl-stream-2 | LXC  | 2     | 2GB  | 32GB    | logging | Cribl Stream processing node 2       |

### LXC Containers - Cribl Edge (181-189)

| ID  | Name           | Type | Cores | RAM  | Storage | Pool    | Purpose                              |
|-----|----------------|------|-------|------|---------|---------|--------------------------------------|
| 181 | cribl-edge-01  | LXC  | 2     | 2GB  | 32GB    | logging | Cribl Edge log forwarder 1           |
| 182 | cribl-edge-02  | LXC  | 2     | 2GB  | 32GB    | logging | Cribl Edge log forwarder 2           |

### LXC Containers - Splunk Management (190-199)

| ID  | Name        | Type | Cores | RAM  | Storage | Pool    | Purpose                              |
|-----|-------------|------|-------|------|---------|---------|--------------------------------------|
| 199 | splunk-mgmt | LXC  | 3     | 3GB  | 100GB   | logging | Splunk SH, DS, LM, MC, CM            |

### VMs - Splunk Enterprise (200+)

| ID  | Name      | Type | Cores | RAM  | Storage | Pool    | Purpose                              |
|-----|-----------|------|-------|------|---------|---------|--------------------------------------|
| 200 | splunk-vm | VM   | 6     | 6GB  | 200GB   | logging | Splunk Enterprise all-in-one         |

---

## Resource Pools

| Pool           | Purpose                              | Resources                                    |
|----------------|--------------------------------------|----------------------------------------------|
| infrastructure | Core infrastructure services         | ansible, ansible-2, pve-scripts-local        |
| ai             | AI development environments          | claude-code-01/02, gemini-01/02              |
| logging        | Logging and observability            | cribl-*, splunk-mgmt, splunk-vm              |

---

## Resource Totals

### Containers (12 total)

| Category       | Cores | RAM   | Storage |
|----------------|-------|-------|---------|
| Infrastructure | 5     | 4.5GB | 136GB   |
| AI Development | 8     | 8GB   | 256GB   |
| Cribl Stream   | 4     | 4GB   | 64GB    |
| Cribl Edge     | 4     | 4GB   | 64GB    |
| Splunk Mgmt    | 3     | 3GB   | 100GB   |
| **Subtotal**   | 24    | 23.5GB| 620GB   |

### VMs (1 total)

| Category       | Cores | RAM   | Storage |
|----------------|-------|-------|---------|
| Splunk VM      | 6     | 6GB   | 200GB   |

### Grand Total

- **Cores**: 30 (oversubscribed)
- **RAM**: 29.5GB
- **Storage**: 820GB

---

## Network Addressing

All resources use /32 host addresses in the management network.

Example configuration uses 192.168.1.0/24:

### Infrastructure (100-110)

- 192.168.1.100/32 - ansible
- 192.168.1.101/32 - ansible-2
- 192.168.1.102/32 - pve-scripts-local

### AI Development (150-169)

- 192.168.1.150/32 - claude-code-01
- 192.168.1.151/32 - claude-code-02
- 192.168.1.161/32 - gemini-01
- 192.168.1.162/32 - gemini-02

### Cribl Stream (171-179)

- 192.168.1.171/32 - cribl-stream-1
- 192.168.1.172/32 - cribl-stream-2

### Cribl Edge (181-189)

- 192.168.1.181/32 - cribl-edge-01
- 192.168.1.182/32 - cribl-edge-02

### Splunk Management (190-199)

- 192.168.1.199/32 - splunk-mgmt

### VMs (200+)

- 192.168.1.200/32 - splunk-vm

---

## Splunk Configuration

### Architecture

Single all-in-one Splunk Enterprise deployment:

- **VM (200)**: Splunk Enterprise with all data roles
- **Container (199)**: Management roles (SH, DS, LM, MC, CM)

### Splunk Network

```text
192.168.1.199,192.168.1.200
```

### Port Matrix

| Port | Protocol | Purpose             | Allowed From            |
|------|----------|---------------------|-------------------------|
| 22   | TCP      | SSH                 | management_network      |
| 8000 | TCP      | Splunk Web UI       | management_network      |
| 8089 | TCP      | Splunk Management   | Splunk network          |
| 9997 | TCP      | Splunk Forwarding   | Splunk network + Cribl  |
| 8080 | TCP      | Replication         | Splunk network          |
| 9887 | TCP      | Clustering          | Splunk network          |

---

## Terraform Management

### State

All resources are 100% Terraform-managed:

- 12 LXC containers
- 1 VM (Splunk)
- 3 resource pools
- Firewall rules

### Configuration

See `terraform.tfvars.example` for complete configuration templates.

### Fresh Deploy

To deploy from scratch (e.g., after PVE 9.x upgrade):

```bash
terragrunt apply
```

This will create all 19 resources from the configuration.

---

## Reserved Ranges

| Range     | Purpose                              |
|-----------|--------------------------------------|
| 100-110   | Infrastructure containers            |
| 111-149   | Reserved                             |
| 150-169   | AI development containers            |
| 170       | Reserved                             |
| 171-179   | Cribl Stream containers              |
| 180       | Reserved                             |
| 181-189   | Cribl Edge containers                |
| 190-199   | Splunk management containers         |
| 200       | Splunk Enterprise VM                 |
| 201-299   | Reserved for future VMs              |
