# OpenHands Integration Guide

This document provides a comprehensive guide for integrating OpenHands as an autonomous AI software engineer alongside or as a replacement for auto-claude in the development environment.

## Overview

[OpenHands](https://openhands.dev/) (formerly OpenDevin) is an open-source platform for AI-driven software development. It creates autonomous AI agents that can write code, execute commands, browse the web, and interact with APIs - effectively acting as an AI software engineer.

### Key Features

- **Autonomous Development**: AI agents that can independently solve coding tasks
- **Multi-Provider Support**: Works with Claude, GPT-4, and other LLMs
- **GitHub/GitLab Integration**: Automated issue resolution via GitHub Actions
- **Multiple Interfaces**: Web UI, CLI, and SDK for programmatic control
- **Docker-Based Sandboxing**: Secure code execution environment
- **Enterprise Ready**: Self-hosted via Kubernetes with VPC support
- **SWE-Bench Performance**: Solves 50%+ of real GitHub issues in benchmarks
- **Recent Funding**: $18.8M Series A led by Madrona (MIT licensed)

## Installation Methods

### Option 1: Docker (Recommended for GUI)

```bash
# Pull the runtime image
docker pull docker.openhands.dev/openhands/runtime:1.0-nikolaik

# Run OpenHands with GUI
docker run -it --rm --pull=always \
  -e SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.openhands.dev/openhands/runtime:1.0-nikolaik \
  -e LOG_ALL_EVENTS=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.openhands:/.openhands \
  -p 3000:3000 \
  --add-host host.docker.internal:host-gateway \
  --name openhands-app \
  docker.openhands.dev/openhands/openhands:1.0
```

Access at: http://localhost:3000

### Option 2: Pip/uv (Recommended for CLI)

```bash
# Using pip
pip install openhands-ai

# Using uv (recommended for best experience)
uv pip install openhands-ai

# Launch GUI server
openhands serve

# With GPU support
openhands serve --gpu

# Mount current directory
openhands serve --mount-cwd
```

### Option 3: Cloud

Access via [app.all-hands.dev](https://app.all-hands.dev) with GitHub authentication.

## Nix Configuration

OpenHands does not yet have an official Nix flake. The recommended approach is to use Docker within a Nix environment or create a custom derivation.

### Docker-in-Nix Approach

```nix
# shells/openhands/flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
  let
    system = "aarch64-darwin"; # or x86_64-linux
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        docker
        docker-compose
        python312
        uv
      ];

      shellHook = ''
        echo "OpenHands development environment"
        echo ""
        echo "To install OpenHands CLI:"
        echo "  uv pip install openhands-ai"
        echo ""
        echo "To run OpenHands GUI (Docker):"
        echo "  docker run -it --rm --pull=always \\"
        echo "    -e SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.openhands.dev/openhands/runtime:1.0-nikolaik \\"
        echo "    -v /var/run/docker.sock:/var/run/docker.sock \\"
        echo "    -v ~/.openhands:/.openhands \\"
        echo "    -p 3000:3000 \\"
        echo "    --add-host host.docker.internal:host-gateway \\"
        echo "    docker.openhands.dev/openhands/openhands:1.0"
      '';
    };
  };
}
```

### Python Derivation (Advanced)

```nix
# packages/openhands/default.nix
{ lib, python312Packages, fetchPypi }:

python312Packages.buildPythonPackage rec {
  pname = "openhands-ai";
  version = "1.0.0"; # Check PyPI for latest

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-..."; # Get from PyPI
  };

  # Note: OpenHands has many dependencies
  # This is a simplified example
  propagatedBuildInputs = with python312Packages; [
    aiohttp
    docker
    litellm
    # ... many more
  ];

  meta = with lib; {
    description = "AI-driven development platform";
    homepage = "https://openhands.dev";
    license = licenses.mit;
  };
}
```

## Configuration

OpenHands uses TOML configuration files:

**Location**: `~/.openhands/config.toml` or `config.toml` in project root

### Example Configuration

```toml
[core]
workspace_base = "./workspace"
run_as_openhands = true

[llm]
model = "anthropic/claude-sonnet-4-20250514"
api_key = "${ANTHROPIC_API_KEY}"
# Or for OpenAI:
# model = "openai/gpt-4o"
# api_key = "${OPENAI_API_KEY}"

[sandbox]
container_image = "docker.openhands.dev/openhands/runtime:1.0-nikolaik"
timeout = 120

[agent]
memory_enabled = false
memory_max_threads = 2
```

## Comparison: OpenHands vs Auto-Claude

### Feature Matrix

| Feature | OpenHands | Auto-Claude |
|---------|-----------|-------------|
| **Architecture** | Autonomous agent platform | Multi-session AI coding |
| **LLM Providers** | Claude, GPT-4, many others | Claude only (via SDK) |
| **Open Source** | Yes (MIT licensed) | Yes |
| **GitHub Actions** | Built-in resolver | Custom integration |
| **Web UI** | Full GUI at port 3000 | Electron app |
| **CLI** | Yes (`openhands`) | Yes |
| **SDK** | Python SDK | Python backend |
| **Nix Support** | Docker-based (no native flake) | Requires packaging |
| **Memory System** | Optional agent memory | Graphiti graph database |
| **Slack Integration** | Cloud feature (source-available) | Custom integration |
| **Issue Resolution** | Automated via GitHub Action | Manual |
| **Self-Contributing** | Yes (37% of own commits) | No |
| **Enterprise** | Kubernetes self-hosted | Desktop-focused |
| **Funding** | $18.8M Series A | Community |

### Strengths of OpenHands

1. **Autonomous Operation**: Can independently solve entire GitHub issues
2. **GitHub Actions Integration**: Native workflow for automated issue resolution
3. **Web UI**: Professional GUI similar to Devin/Jules
4. **Enterprise Ready**: Kubernetes deployment with VPC support
5. **Active Development**: Well-funded, high commit velocity
6. **Benchmark Performance**: 50%+ on SWE-bench real issues
7. **Self-Improving**: Contributes to its own codebase

### Strengths of Auto-Claude

1. **Graphiti Memory**: Cross-session knowledge graph
2. **Linear/GitHub Integration**: Project management integrations
3. **Session Insights**: Automatic pattern extraction
4. **Multi-Session**: Parallel agent orchestration
5. **Desktop Focus**: Optimized for local development

### Migration Considerations

**What OpenHands CAN replace from auto-claude:**
- Core AI coding capabilities
- File editing and code generation
- Terminal command execution
- GitHub issue resolution (better automation)
- Web UI for agent interaction

**What requires custom implementation:**
- Slack real-time status logging (Cloud feature, source-available)
- OTEL/monitoring integration (would need custom implementation)
- Graph-based memory system (different architecture)
- Linear integration (not native)

## OrbStack Integration

OpenHands works well with OrbStack's Docker environment on macOS.

### Running OpenHands in OrbStack

```bash
# Ensure OrbStack Docker is running
# OrbStack automatically provides Docker socket

# Run OpenHands
docker run -it --rm --pull=always \
  -e SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.openhands.dev/openhands/runtime:1.0-nikolaik \
  -e LOG_ALL_EVENTS=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.openhands:/.openhands \
  -v $(pwd):/workspace \
  -p 3000:3000 \
  --add-host host.docker.internal:host-gateway \
  --name openhands-app \
  docker.openhands.dev/openhands/openhands:1.0
```

### With OrbStack Kubernetes

```yaml
# openhands-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openhands
spec:
  replicas: 1
  selector:
    matchLabels:
      app: openhands
  template:
    metadata:
      labels:
        app: openhands
    spec:
      containers:
      - name: openhands
        image: docker.openhands.dev/openhands/openhands:1.0
        ports:
        - containerPort: 3000
        env:
        - name: SANDBOX_RUNTIME_CONTAINER_IMAGE
          value: docker.openhands.dev/openhands/runtime:1.0-nikolaik
        - name: LOG_ALL_EVENTS
          value: "true"
        volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
        - name: openhands-config
          mountPath: /.openhands
      volumes:
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
      - name: openhands-config
        persistentVolumeClaim:
          claimName: openhands-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: openhands
spec:
  type: LoadBalancer
  ports:
  - port: 3000
    targetPort: 3000
  selector:
    app: openhands
```

## GitHub Actions Integration

OpenHands provides native GitHub Actions for automated issue resolution.

### Setup

1. Create a GitHub Personal Access Token with scopes:
   - `contents` (read/write)
   - `issues` (read/write)
   - `pull_requests` (read/write)
   - `workflows` (read/write)

2. Add secrets to your repository:
   - `OPENHANDS_PAT`: Your GitHub PAT
   - `LLM_API_KEY`: Claude or OpenAI API key

3. Create workflow file:

```yaml
# .github/workflows/openhands-resolver.yml
name: OpenHands Issue Resolver

on:
  issues:
    types: [labeled]

jobs:
  resolve-issue:
    if: github.event.label.name == 'fix-me'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install OpenHands Resolver
        run: pip install openhands-resolver

      - name: Resolve Issue
        env:
          GITHUB_TOKEN: ${{ secrets.OPENHANDS_PAT }}
          LLM_API_KEY: ${{ secrets.LLM_API_KEY }}
          LLM_MODEL: anthropic/claude-sonnet-4-20250514
        run: |
          python -m openhands.resolver.resolve_issue \
            --repo ${{ github.repository }} \
            --issue-number ${{ github.event.issue.number }}
```

### How It Works

1. Label an issue with `fix-me`
2. GitHub Action triggers OpenHands resolver
3. OpenHands analyzes the issue and attempts a fix
4. If successful, creates a PR with the solution
5. 37% of OpenHands' own commits come from this process

## Terraform Integration

OpenHands can assist with Terraform/Terragrunt development through its code editing and command execution capabilities.

### Workflow

1. Point OpenHands at your Terraform repository
2. Describe the infrastructure changes needed
3. OpenHands can:
   - Read and understand existing Terraform configs
   - Create/modify resource definitions
   - Run `terraform validate` and `terraform plan`
   - Fix validation errors iteratively

### Example Prompt

```
Review the Terraform configuration in this repository and:
1. Add a new proxmox_virtual_environment_vm resource for a monitoring server
2. Ensure it follows the existing module patterns
3. Run terraform validate to check the syntax
4. Create appropriate variable definitions
```

## Slack Integration

OpenHands Cloud includes Slack integration as a source-available feature. For self-hosted deployments, custom integration is required.

### Custom Slack Notification Script

```python
# scripts/openhands-slack-notify.py
import os
import json
import requests
from datetime import datetime

SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")

def send_slack_notification(event_type: str, details: dict):
    """Send OpenHands event to Slack."""
    if not SLACK_WEBHOOK_URL:
        return

    color_map = {
        "session_start": "#36a64f",
        "task_complete": "#2eb886",
        "task_failed": "#dc3545",
        "pr_created": "#6f42c1",
    }

    payload = {
        "attachments": [{
            "color": color_map.get(event_type, "#808080"),
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": f"OpenHands: {event_type.replace('_', ' ').title()}"
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*Repository:*\n{details.get('repo', 'N/A')}"},
                        {"type": "mrkdwn", "text": f"*Issue:*\n#{details.get('issue', 'N/A')}"},
                    ]
                },
                {
                    "type": "context",
                    "elements": [
                        {"type": "mrkdwn", "text": f"Timestamp: {datetime.now().isoformat()}"}
                    ]
                }
            ]
        }]
    }

    requests.post(SLACK_WEBHOOK_URL, json=payload)

# Usage in GitHub Action:
# python scripts/openhands-slack-notify.py session_start '{"repo": "myorg/myrepo", "issue": 123}'
if __name__ == "__main__":
    import sys
    if len(sys.argv) >= 3:
        event = sys.argv[1]
        details = json.loads(sys.argv[2])
        send_slack_notification(event, details)
```

### GitHub Action with Slack

```yaml
# .github/workflows/openhands-resolver-slack.yml
name: OpenHands Issue Resolver with Slack

on:
  issues:
    types: [labeled]

jobs:
  resolve-issue:
    if: github.event.label.name == 'fix-me'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Notify Slack - Started
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: |
          curl -X POST $SLACK_WEBHOOK_URL \
            -H 'Content-type: application/json' \
            -d '{"text": "🤖 OpenHands starting work on issue #${{ github.event.issue.number }}"}'

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install OpenHands Resolver
        run: pip install openhands-resolver

      - name: Resolve Issue
        id: resolve
        env:
          GITHUB_TOKEN: ${{ secrets.OPENHANDS_PAT }}
          LLM_API_KEY: ${{ secrets.LLM_API_KEY }}
          LLM_MODEL: anthropic/claude-sonnet-4-20250514
        run: |
          python -m openhands.resolver.resolve_issue \
            --repo ${{ github.repository }} \
            --issue-number ${{ github.event.issue.number }}

      - name: Notify Slack - Completed
        if: success()
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: |
          curl -X POST $SLACK_WEBHOOK_URL \
            -H 'Content-type: application/json' \
            -d '{"text": "✅ OpenHands completed work on issue #${{ github.event.issue.number }}"}'

      - name: Notify Slack - Failed
        if: failure()
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: |
          curl -X POST $SLACK_WEBHOOK_URL \
            -H 'Content-type: application/json' \
            -d '{"text": "❌ OpenHands failed on issue #${{ github.event.issue.number }}"}'
```

## Recommended Architecture

For the JacobPEvans/nix repository:

```text
nix-config/
├── flake.nix                     # Main flake
├── shells/
│   ├── terraform/                # Existing Terraform shell
│   │   └── flake.nix
│   ├── openhands/                # NEW: OpenHands development shell
│   │   ├── flake.nix
│   │   └── config/
│   │       └── config.toml       # OpenHands config template
│   └── terraform-openhands/      # NEW: Combined shell
│       └── flake.nix
├── scripts/
│   └── openhands-slack-notify.py # Slack notification helper
└── .github/
    └── workflows/
        └── openhands-resolver.yml # GitHub Action for auto-resolution
```

## Migration Path from Auto-Claude

### Phase 1: Parallel Evaluation
1. Install OpenHands alongside auto-claude
2. Test OpenHands on non-critical issues
3. Compare output quality and reliability

### Phase 2: GitHub Actions Setup
1. Configure OpenHands resolver workflow
2. Test automated issue resolution
3. Add Slack notifications to workflow

### Phase 3: Gradual Migration
1. Use OpenHands for new GitHub issues
2. Keep auto-claude for complex multi-session tasks
3. Document any capability gaps

### Phase 4: Full Replacement (If Appropriate)
1. Migrate remaining workflows to OpenHands
2. Consider OpenHands Cloud for Slack/Jira/Linear integrations
3. Archive auto-claude configuration

## Monitoring and Logging

### Enable Full Event Logging

```bash
docker run ... -e LOG_ALL_EVENTS=true ...
```

### Log Location

Logs are stored in `~/.openhands/` directory:
- Session logs
- Agent conversation history
- Command execution logs

### OTEL Integration (Custom)

OpenHands doesn't have native OTEL support. For monitoring integration with Cribl/Splunk:

```python
# Custom wrapper for OTEL export
import json
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

tracer = trace.get_tracer("openhands")

def trace_openhands_session(session_id: str, issue_number: int):
    with tracer.start_as_current_span("openhands.session") as span:
        span.set_attribute("session.id", session_id)
        span.set_attribute("issue.number", issue_number)
        # ... run OpenHands
```

## Sources

- [OpenHands Official Site](https://openhands.dev/)
- [OpenHands GitHub](https://github.com/OpenHands/OpenHands)
- [OpenHands Documentation](https://docs.openhands.dev/)
- [OpenHands PyPI](https://pypi.org/project/openhands-ai/)
- [OpenHands GitHub Action](https://github.com/OpenHands/openhands-github-action)
- [OpenHands Resolver](https://pypi.org/project/openhands-resolver/)
- [OpenHands Funding Announcement](https://openhands.dev/blog/weve-just-raised-18-8m-to-build-the-open-standard-for-autonomous-software-development)
- [Auto-Claude GitHub](https://github.com/AndyMik90/Auto-Claude)
- [OrbStack Documentation](https://docs.orbstack.dev/)
