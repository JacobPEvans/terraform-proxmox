# Infrastructure Numbering Scheme

**Version**: 2.0
**Date**: 2025-12-27
**Status**: Active

---

## Numbering Conventions

### VMs (100-199)
Only Splunk indexers remain as VMs for optimal I/O performance

### LXC Containers (200-299)
All other services run as lightweight containers, numbered in increments of 5 (except Cribl Edge pair)

---

## Complete Infrastructure Map

### VMs - Splunk Indexers (100-101)

| ID  | Name         | Type | Cores | RAM  | Storage | Purpose                    |
|-----|--------------|------|-------|------|---------|----------------------------|
| 100 | splunk-idx1  | VM   | 6     | 6GB  | 200GB   | Splunk indexer peer 1      |
| 101 | splunk-idx2  | VM   | 6     | 6GB  | 200GB   | Splunk indexer peer 2      |

**Total VM Resources**: 12 cores, 12GB RAM, 400GB storage

### LXC Containers - Control Plane (200-209)

| ID  | Name          | Type | Cores | RAM  | Storage | Purpose                              |
|-----|---------------|------|-------|------|---------|--------------------------------------|
| 200 | ansible       | LXC  | 2     | 2GB  | 64GB    | Ansible control node                 |
| 205 | splunk-mgmt   | LXC  | 3     | 3GB  | 100GB   | Splunk management (all-in-one)       |

### LXC Containers - Log Forwarding (210-219)

| ID  | Name          | Type | Cores | RAM  | Storage | Purpose                              |
|-----|---------------|------|-------|------|---------|--------------------------------------|
| 210 | cribl-edge-1  | LXC  | 2     | 2GB  | 32GB    | Cribl Edge log forwarder 1           |
| 211 | cribl-edge-2  | LXC  | 2     | 2GB  | 32GB    | Cribl Edge log forwarder 2           |

### LXC Containers - AI Development (220-229)

| ID  | Name          | Type | Cores | RAM  | Storage | Purpose                              |
|-----|---------------|------|-------|------|---------|--------------------------------------|
| 220 | claude1       | LXC  | 2     | 2GB  | 64GB    | Claude Code development environment  |

**Reserved for Future Use**: 221-225 (claude2, gemini1/2, copilot, llm)

**Total Container Resources**: 9 cores, 9GB RAM, 192GB storage

---

## Resource Totals

- **VMs**: 12 cores, 12GB RAM, 400GB storage
- **Containers**: 9 cores, 9GB RAM, 192GB storage
- **Grand Total**: 21 cores, 21GB RAM, 592GB storage

**Hardware Capacity**: Ryzen 7 1700 (8 cores), 16GB RAM
**Oversubscription**: 2.6x CPU, 1.3x RAM (conservative allocation)

---

## Network Addressing

All resources use /32 host addresses in 192.168.1.0/24 network:

### VMs
- 192.168.1.100/32 - splunk-idx1
- 192.168.1.101/32 - splunk-idx2

### Control Plane
- 192.168.1.200/32 - ansible
- 192.168.1.205/32 - splunk-mgmt

### Log Forwarding
- 192.168.1.210/32 - cribl-edge-1
- 192.168.1.211/32 - cribl-edge-2

### AI Development
- 192.168.1.220/32 - claude1
- 192.168.1.221-225/32 - Reserved for future AI containers

---

## Migration from Old Numbering

| Old ID | Old Name      | New ID | New Name      | Type Change |
|--------|---------------|--------|---------------|-------------|
| 100    | ansible       | 200    | ansible       | VM → LXC    |
| 110    | claude        | 220    | claude1       | VM → LXC    |
| 120    | syslog        | 210/211| cribl-edge-*  | VM → 2xLXC  |
| 130    | splunk        | 205    | splunk-mgmt   | VM → LXC    |
| 135    | splunk-idx1   | 100    | splunk-idx1   | VM (renumbered) |
| 136    | splunk-idx2   | 101    | splunk-idx2   | VM (renumbered) |
| 140    | containers    | -      | REMOVED       | Deprecated  |

---

## Splunk Cluster Configuration

### Cluster Architecture
- **Replication Factor**: 2 (both indexers)
- **Search Factor**: 1
- **Cluster Manager**: splunk-mgmt (205)
- **Cluster Manager URI**: https://192.168.1.205:8089

### Splunk Network
```
192.168.1.100,192.168.1.101,192.168.1.205
```

### Port Matrix

| Port | Protocol | Purpose             | Allowed From            |
|------|----------|---------------------|-------------------------|
| 22   | TCP      | SSH                 | 192.168.1.0/24          |
| 8000 | TCP      | Splunk Web UI       | 192.168.1.0/24          |
| 8089 | TCP      | Splunk Management   | Splunk cluster only     |
| 9997 | TCP      | Splunk Forwarding   | Splunk cluster + Cribl  |
| 8080 | TCP      | Replication         | Splunk cluster only     |
| 9887 | TCP      | Clustering          | Splunk cluster only     |

---

## Terraform State Management

### Managed Resources

**VMs**: 2 (splunk-idx1, splunk-idx2)
**Containers**: 1 (splunk-mgmt) - others are manually created
**Pools**: Optional "logging" pool for Splunk resources

### Unmanaged Resources

All AI development and control plane containers are created manually via Proxmox UI for operational flexibility.

---

## Reserved Ranges

- **100-149**: VMs (currently only 100-101 used)
- **150-199**: Reserved for future VMs
- **200-209**: Control plane containers
- **210-219**: Log forwarding containers
- **220-229**: AI development containers
- **230-299**: Reserved for future containers

---

## Change History

### Current Scheme (2025-12-27)
- Complete renumbering: VMs to 100-series, containers to 200-series
- Splunk indexers upgraded: 4→6 cores, 4→6GB RAM, storage remains 200GB
- Initial deployment: claude1 (220) as primary AI development container
- Reserved IDs 221-225 for future AI containers (claude2, gemini1/2, copilot, llm)
- Removed containers VM (140) - replaced with native containers approach

### v1.0 (2025-08-04)
- Initial numbering: ansible=100, claude=110, syslog=120, splunk=130, splunk-idx1=135, splunk-idx2=136, containers=140
