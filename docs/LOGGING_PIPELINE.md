# Logging Pipeline Architecture

## Overview

This document describes the syslog logging pipeline from network devices through to Splunk Enterprise for security monitoring and analysis.

## Data Flow

```text
Syslog Sources              Load Balancer       Syslog Collectors      Processing         Destination
+----------------+          +----------+        +---------------+      +-----------+      +--------+
| UniFi (1514)   |          |          |        | cribl-edge-01 |      |           |      |        |
| Palo Alto(1515)|   --->   | HAProxy  |  --->  |               | ---> | Cribl     | ---> | Splunk |
| Cisco (1516)   |          | :1514-18 |        | cribl-edge-02 |      | Stream    |      | HEC    |
| Linux (1517)   |          +----------+        +---------------+      +-----------+      +--------+
| Windows (1518) |                                   |                       |
+----------------+                                   |                       |
                                                     v                       v
                                              100GB queue disk         Persistent queue
                                              (survives outages)       for reliability
```

## Components

### 1. Syslog Sources

Network devices and hosts configured to send syslog to `haproxy.jacobpevans.com`.

| Source           | Port | Protocol | Index    |
| ---------------- | ---- | -------- | -------- |
| UniFi Dream Wall | 1514 | UDP/TCP  | unifi    |
| Palo Alto        | 1515 | UDP/TCP  | firewall |
| Cisco ASA        | 1516 | UDP/TCP  | firewall |
| Linux hosts      | 1517 | UDP/TCP  | os       |
| Windows hosts    | 1518 | UDP/TCP  | os       |

### 2. HAProxy Load Balancer

- **Host**: haproxy (VMID 175, LXC container)
- **IP**: 10.0.1.175
- **Function**: Round-robin load balancing to Cribl Edge nodes
- **Health checks**: Every 5 seconds
- **Stats**: Port 8404

### 3. Cribl Edge (Syslog Collectors)

Two-node cluster for high availability and horizontal scaling.

| Node          | VMID | IP         |
| ------------- | ---- | ---------- |
| cribl-edge-01 | 180  | 10.0.1.180 |
| cribl-edge-02 | 181  | 10.0.1.181 |

**Features**:

- Syslog parsing and normalization
- 100GB persistent queue disk for outage survival
- Forwards to Cribl Stream for central processing

### 4. Cribl Stream (Central Processor)

- **Host**: cribl-stream-01 (VMID 182, LXC container)
- **IP**: 10.0.1.182
- **Function**: Central log processing, routing, and enrichment
- **Output**: Splunk HEC over HTTPS

### 5. Splunk Enterprise

- **Host**: splunk (VMID 200, VM)
- **IP**: 10.0.1.200
- **Web UI**: Port 8000
- **HEC Endpoint**: Port 8088 (TLS)

## Network Ports

| Port | Service       | Protocol | Purpose          |
| ---- | ------------- | -------- | ---------------- |
| 1514 | HAProxy/Cribl | UDP/TCP  | UniFi syslog     |
| 1515 | HAProxy/Cribl | UDP/TCP  | Palo Alto syslog |
| 1516 | HAProxy/Cribl | UDP/TCP  | Cisco ASA syslog |
| 1517 | HAProxy/Cribl | UDP/TCP  | Linux syslog     |
| 1518 | HAProxy/Cribl | UDP/TCP  | Windows syslog   |
| 8000 | Splunk        | TCP      | Web interface    |
| 8088 | Splunk        | TCP/TLS  | HEC endpoint     |
| 8404 | HAProxy       | TCP      | Statistics page  |

## Reliability Features

1. **Load balancing**: HAProxy distributes load across Cribl Edge nodes
2. **Health checks**: 5-second intervals detect node failures
3. **Persistent queues**: 100GB disk survives Splunk outages
4. **TLS encryption**: HEC traffic encrypted end-to-end

## Deployment

```bash
# Deploy all components via Ansible
cd ~/git/ansible-proxmox-apps
doppler run -- ansible-playbook playbooks/site.yml
```

## Validation

```bash
# Test syslog delivery
logger -n haproxy.jacobpevans.com -P 1514 "Test message $(date +%s)"

# Check HAProxy stats
curl http://10.0.1.175:8404/stats

# Verify Splunk received event
splunk search 'index=unifi earliest=-5m'
```

## Related Documentation

- [SPLUNK_INDEXES.md](./SPLUNK_INDEXES.md) - Index definitions and retention
- [ansible-proxmox-apps README](https://github.com/JacobPEvans/ansible-proxmox-apps) - Ansible roles
