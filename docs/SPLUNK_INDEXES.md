# Splunk Index Configuration

## Overview

This document defines the Splunk indexes used in the logging pipeline, their purpose, and retention policies.

## Index Definitions

| Index    | Purpose                   | Sources                        | Retention |
| -------- | ------------------------- | ------------------------------ | --------- |
| unifi    | UniFi network device logs | Network devices, switches, APs | 365 days  |
| os       | Operating system logs     | Linux, macOS, Windows hosts    | 365 days  |
| firewall | Firewall logs             | Palo Alto, Cisco ASA           | 365 days  |
| network  | General network logs      | Switches, routers, other       | 365 days  |

## Index Configuration

### unifi

```ini
[unifi]
homePath = $SPLUNK_DB/unifi/db
coldPath = $SPLUNK_DB/unifi/colddb
thawedPath = $SPLUNK_DB/unifi/thaweddb
maxTotalDataSizeMB = 102400
frozenTimePeriodInSecs = 31536000
```

**Data types**:

- Connection events (client connects/disconnects)
- Threat detection (IDS/IPS alerts)
- Traffic flows
- System events

### os

```ini
[os]
homePath = $SPLUNK_DB/os/db
coldPath = $SPLUNK_DB/os/colddb
thawedPath = $SPLUNK_DB/os/thaweddb
maxTotalDataSizeMB = 102400
frozenTimePeriodInSecs = 31536000
```

**Data types**:

- Authentication events (login/logout)
- Process execution
- File system events
- System errors

### firewall

```ini
[firewall]
homePath = $SPLUNK_DB/firewall/db
coldPath = $SPLUNK_DB/firewall/colddb
thawedPath = $SPLUNK_DB/firewall/thaweddb
maxTotalDataSizeMB = 102400
frozenTimePeriodInSecs = 31536000
```

**Data types**:

- Traffic permits/denies
- NAT translations
- VPN events
- Threat detection

### network

```ini
[network]
homePath = $SPLUNK_DB/network/db
coldPath = $SPLUNK_DB/network/colddb
thawedPath = $SPLUNK_DB/network/thaweddb
maxTotalDataSizeMB = 102400
frozenTimePeriodInSecs = 31536000
```

**Data types**:

- SNMP traps
- Spanning tree events
- Port status changes
- General network telemetry

## Retention Policy

All indexes use a **365-day retention** period (`frozenTimePeriodInSecs = 31536000`).

**Rationale**:

- Security investigations may require historical data
- Compliance requirements typically need 1 year retention
- Storage capacity supports this duration

## Size Limits

Each index is limited to **100GB** (`maxTotalDataSizeMB = 102400`).

**Capacity planning**:

- Total: 400GB across 4 indexes
- Splunk VM disk: 500GB allocated
- Buffer for internal indexes: 100GB

## Source Type Mapping

| Source Type    | Index    | Description            |
| -------------- | -------- | ---------------------- |
| unifi:usg      | unifi    | UniFi Security Gateway |
| unifi:switch   | unifi    | UniFi switches         |
| unifi:ap       | unifi    | UniFi access points    |
| syslog:linux   | os       | Linux syslog           |
| syslog:macos   | os       | macOS syslog           |
| syslog:windows | os       | Windows Event Log      |
| pan:traffic    | firewall | Palo Alto traffic      |
| pan:threat     | firewall | Palo Alto threats      |
| cisco:asa      | firewall | Cisco ASA              |
| syslog:network | network  | Generic network        |

## HEC Token Configuration

The Splunk HEC token is stored in Doppler as `SPLUNK_HEC_TOKEN`.

**HEC settings**:

- Port: 8088
- TLS: Enabled
- Default index: Based on source type routing in Cribl

## Ansible Configuration

Indexes are configured via the `splunk_docker` role in ansible-proxmox-apps:

```yaml
# roles/splunk_docker/defaults/main.yml
splunk_indexes:
  - name: unifi
    maxTotalDataSizeMB: 102400
    frozenTimePeriodInSecs: 31536000
  - name: os
    maxTotalDataSizeMB: 102400
    frozenTimePeriodInSecs: 31536000
  - name: firewall
    maxTotalDataSizeMB: 102400
    frozenTimePeriodInSecs: 31536000
  - name: network
    maxTotalDataSizeMB: 102400
    frozenTimePeriodInSecs: 31536000
```

## Related Documentation

- [LOGGING_PIPELINE.md](./LOGGING_PIPELINE.md) - Pipeline architecture
- [Splunk Indexes Configuration](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Indexesconf)
