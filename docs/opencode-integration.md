# OpenCode Integration Guide

This document provides a comprehensive guide for integrating OpenCode as an AI coding agent alongside or as a replacement for auto-claude in the Nix-based development environment.

## Overview

[OpenCode](https://opencode.ai/) is an open-source AI coding agent built for the terminal by [SST](https://github.com/sst/opencode). With 41,000+ GitHub stars and 400,000+ monthly users, it provides a provider-agnostic alternative to Claude Code.

### Key Features

- **Multi-Provider Support**: Works with Anthropic Claude, OpenAI, Google Gemini, AWS Bedrock, Groq, Azure OpenAI, OpenRouter, and 75+ other providers
- **Native Nix Support**: Available via `nixpkgs#opencode` or dedicated flake
- **MCP Integration**: Full Model Context Protocol support for external tools
- **Plugin System**: 25+ hooks for event-driven customization
- **Client/Server Architecture**: Enables remote control from mobile apps
- **Built-in Agents**: "build" (full access) and "plan" (read-only) modes
- **LSP Integration**: Code intelligence across programming languages

## Nix Configuration

### Option 1: Nixpkgs (Simplest)

```nix
# In your NixOS or Home Manager configuration
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.opencode ];
  # Or for Home Manager:
  # home.packages = [ pkgs.opencode ];
}
```

### Option 2: Dedicated Flake (Recommended for Latest)

The [opencode-flake](https://github.com/AodhanHayter/opencode-flake) provides auto-updating packages:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode-flake.url = "github:aodhanhayter/opencode-flake";
  };

  outputs = { self, nixpkgs, opencode-flake, ... }:
  let
    system = "aarch64-darwin"; # or "x86_64-linux", "x86_64-darwin"
  in {
    # For Home Manager
    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      modules = [
        {
          home.packages = [
            opencode-flake.packages.${system}.default
          ];
        }
      ];
    };

    # For NixOS
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        {
          environment.systemPackages = [
            opencode-flake.packages.${system}.default
          ];
        }
      ];
    };
  };
}
```

### Option 3: Dev Shell for Projects

```nix
# flake.nix for a project that needs OpenCode
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode-flake.url = "github:aodhanhayter/opencode-flake";
  };

  outputs = { self, nixpkgs, opencode-flake, ... }:
  let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
  in {
    devShells = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = [
            opencode-flake.packages.${system}.default
            # Add other dev tools
          ];
        };
      });
  };
}
```

## OpenCode Configuration

OpenCode uses JSON/JSONC configuration files:

**Global config**: `~/.config/opencode/opencode.json`
**Project config**: `.opencode/config.json` (takes precedence)

### Example Configuration

```jsonc
{
  // Provider configuration
  "provider": {
    "default": "anthropic",
    "anthropic": {
      "model": "claude-sonnet-4-20250514"
    }
  },

  // MCP servers for tool integration
  "mcp": {
    "terraform": {
      "type": "local",
      "command": "terraform-mcp-server",
      "args": [],
      "env": {
        "TFE_TOKEN": "${TFE_TOKEN}"
      }
    },
    "filesystem": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-fs", "/path/to/allowed/dir"]
    }
  },

  // Tool permissions
  "tools": {
    "bash": { "enabled": true },
    "write": { "enabled": true },
    "edit": { "enabled": true }
  }
}
```

## Comparison: OpenCode vs Auto-Claude

### Feature Matrix

| Feature | OpenCode | Auto-Claude |
|---------|----------|-------------|
| **LLM Providers** | 75+ providers | Claude only (via SDK) |
| **Open Source** | Yes (SST) | Yes (AndyMik90) |
| **Nix Support** | Native (nixpkgs, flake) | Requires custom packaging |
| **Plugin System** | 25+ event hooks | Limited |
| **Memory System** | Session-based | Graphiti graph database |
| **MCP Support** | Full | Limited |
| **GitHub Actions** | Built-in (/opencode) | Via custom integration |
| **Desktop App** | Yes | Electron app |
| **IDE Extension** | VS Code, Cursor | VS Code |
| **Slack Integration** | Custom plugin needed | Via custom integration |
| **OTEL Support** | Via custom plugin | stderr/stdout logging |

### Strengths of OpenCode

1. **Provider Agnostic**: Not locked to any single AI provider
2. **Native Nix**: First-class Nix support with auto-updating flakes
3. **MCP Ecosystem**: Access to growing MCP tool ecosystem
4. **Active Development**: High commit velocity, large community
5. **TUI Focus**: Built by neovim/terminal.shop developers
6. **Privacy Control**: Choose what data is shared and where

### Strengths of Auto-Claude

1. **Graphiti Memory**: Cross-session knowledge graph for context
2. **Linear/GitHub Integration**: Native project management integration
3. **Session Insights**: Automatic pattern extraction
4. **Multi-Session**: Parallel agent orchestration
5. **Mature Monitoring**: Better logging infrastructure

### Migration Considerations

**What OpenCode CAN replace from auto-claude:**
- Core AI coding capabilities
- File editing and code generation
- Terminal command execution
- GitHub integration (via /opencode in Actions)
- IDE integration

**What requires custom implementation:**
- Slack real-time status logging (requires custom plugin)
- OTEL/monitoring integration (requires custom plugin)
- Graph-based memory system (different architecture)
- Linear integration (not native, could use MCP)

## OrbStack Integration

OpenCode works natively with OrbStack's Docker and Kubernetes environments on macOS.

### Running OpenCode in OrbStack Container

```dockerfile
# Dockerfile for OpenCode container
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl git

# Install OpenCode
RUN curl -fsSL https://opencode.ai/install | bash

# Copy auth from host (mount at runtime)
# Your auth is in ~/.local/share/opencode/auth.json

WORKDIR /workspace
CMD ["opencode"]
```

```bash
# Build and run
docker build -t opencode-dev .

# Run with auth mounted (OrbStack on macOS)
docker run -it \
  -v ~/.local/share/opencode:/root/.local/share/opencode \
  -v $(pwd):/workspace \
  opencode-dev
```

### Kubernetes Development with OpenCode

With OrbStack's Kubernetes cluster:

```yaml
# opencode-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: opencode-dev
spec:
  containers:
  - name: opencode
    image: opencode-dev:latest
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    - name: opencode-auth
      mountPath: /root/.local/share/opencode
  volumes:
  - name: workspace
    hostPath:
      path: /path/to/your/project
  - name: opencode-auth
    secret:
      secretName: opencode-auth
```

## Terraform Integration

OpenCode integrates with Terraform via the [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server).

### Setup

```jsonc
// ~/.config/opencode/opencode.json
{
  "mcp": {
    "terraform": {
      "type": "local",
      "command": "terraform-mcp-server",
      "env": {
        "TFE_TOKEN": "${TFE_TOKEN}",
        "TFE_ADDRESS": "app.terraform.io"
      }
    }
  }
}
```

### Capabilities

With Terraform MCP, OpenCode can:
- Browse Terraform Registry for providers and modules
- Manage HCP Terraform/Terraform Enterprise workspaces
- Access private registry resources
- Query provider documentation

### Nix Integration for Terraform + OpenCode

```nix
# shells/terraform-opencode/flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode-flake.url = "github:aodhanhayter/opencode-flake";
  };

  outputs = { nixpkgs, opencode-flake, ... }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        opencode-flake.packages.${system}.default
        pkgs.terraform
        pkgs.terragrunt
        pkgs.aws-vault
        # terraform-mcp-server would need packaging
      ];

      shellHook = ''
        echo "OpenCode + Terraform environment ready"
        echo "Run: opencode"
      '';
    };
  };
}
```

## Custom Plugin: Slack Notifications

OpenCode plugins are JS/TS modules that hook into events. Here's how to create Slack integration:

### Plugin Structure

```typescript
// ~/.config/opencode/plugin/slack-notify.ts
import { IncomingWebhook } from "@slack/webhook";

const webhookUrl = process.env.SLACK_WEBHOOK_URL || "";
const webhook = new IncomingWebhook(webhookUrl);

export default function slackNotifyPlugin(context: any) {
  return {
    "session.start": async (event: any) => {
      await webhook.send({
        text: `:rocket: OpenCode session started`,
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: `*Session Started*\nProject: ${event.project || "unknown"}`,
            },
          },
        ],
      });
    },

    "session.idle": async (event: any) => {
      await webhook.send({
        text: `:zzz: OpenCode session idle`,
      });
    },

    "tool.execute.after": async (event: any) => {
      // Log tool executions
      if (event.tool === "bash" || event.tool === "write") {
        await webhook.send({
          text: `:hammer_and_wrench: Tool executed: ${event.tool}`,
        });
      }
    },

    "chat.message": async (event: any) => {
      // Log assistant responses (summarized)
      if (event.role === "assistant" && event.content?.length > 0) {
        const summary = event.content.substring(0, 200);
        await webhook.send({
          text: `:speech_balloon: Assistant: ${summary}...`,
        });
      }
    },

    "session.compacting": async (event: any) => {
      await webhook.send({
        text: `:compression: Session compacting - context limit approaching`,
      });
    },
  };
}
```

### Install Dependencies

```bash
# OpenCode uses Bun for plugin dependencies
cd ~/.config/opencode/plugin
bun add @slack/webhook
```

## Custom Plugin: OTEL/Monitoring

For OpenTelemetry integration similar to Claude Code monitoring:

```typescript
// ~/.config/opencode/plugin/otel-trace.ts
import { trace, SpanStatusCode } from "@opentelemetry/api";

const tracer = trace.getTracer("opencode");

export default function otelPlugin(context: any) {
  let sessionSpan: any = null;

  return {
    "session.start": async (event: any) => {
      sessionSpan = tracer.startSpan("opencode.session", {
        attributes: {
          "session.id": event.sessionId,
          "project.name": event.project,
        },
      });
    },

    "tool.execute.before": async (event: any) => {
      const span = tracer.startSpan(`opencode.tool.${event.tool}`, {
        parent: sessionSpan,
      });
      event._span = span;
    },

    "tool.execute.after": async (event: any) => {
      if (event._span) {
        event._span.setStatus({ code: SpanStatusCode.OK });
        event._span.end();
      }
    },

    "session.end": async (event: any) => {
      if (sessionSpan) {
        sessionSpan.end();
      }
    },
  };
}
```

## Ansible Integration

OpenCode can assist with Ansible development through:

1. **Native Understanding**: OpenCode understands YAML and Ansible syntax
2. **MCP for Ansible Docs**: Potential MCP server for Ansible documentation
3. **File System Access**: Direct editing of playbooks and roles

### Recommended Workflow

```bash
# In your Nix shell with OpenCode
nix develop ~/git/nix-config/main/shells/ansible-opencode

# Start OpenCode in your Ansible role directory
cd ansible/roles/my-role
opencode

# Ask OpenCode to:
# - Write/edit tasks
# - Create molecule tests
# - Lint and fix issues
```

## Recommended Architecture

For the JacobPEvans/nix repository, the recommended structure:

```text
nix-config/
├── flake.nix                     # Main flake
├── shells/
│   ├── terraform/                # Existing Terraform shell
│   │   └── flake.nix
│   ├── opencode/                 # NEW: Dedicated OpenCode shell
│   │   ├── flake.nix
│   │   └── config/               # OpenCode config templates
│   │       ├── opencode.json
│   │       └── plugins/
│   │           ├── slack-notify.ts
│   │           └── otel-trace.ts
│   └── terraform-opencode/       # NEW: Combined shell
│       └── flake.nix
├── modules/
│   └── opencode/                 # NEW: Home Manager module
│       └── default.nix
└── overlays/
    └── opencode.nix              # Optional overlay for customization
```

### Home Manager Module Example

```nix
# modules/opencode/default.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.opencode;
in {
  options.programs.opencode = {
    enable = mkEnableOption "OpenCode AI coding agent";

    package = mkOption {
      type = types.package;
      default = pkgs.opencode;
      description = "OpenCode package to use";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "OpenCode configuration (JSON)";
    };

    plugins = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Plugin files to install";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."opencode/opencode.json" = mkIf (cfg.settings != {}) {
      text = builtins.toJSON cfg.settings;
    };

    xdg.configFile = mkMerge (map (plugin: {
      "opencode/plugin/${builtins.baseNameOf plugin}".source = plugin;
    }) cfg.plugins);
  };
}
```

## Migration Path from Auto-Claude

### Phase 1: Parallel Operation
1. Install OpenCode alongside auto-claude
2. Test OpenCode on non-critical tasks
3. Develop custom plugins for Slack/OTEL

### Phase 2: Feature Parity
1. Implement Slack notification plugin
2. Configure OTEL tracing plugin
3. Set up Terraform MCP integration
4. Test GitHub Actions integration

### Phase 3: Gradual Migration
1. Start using OpenCode for new projects
2. Document any gaps or issues
3. Contribute upstream fixes if needed

### Phase 4: Full Replacement (If Appropriate)
1. Migrate remaining workflows to OpenCode
2. Archive auto-claude configuration
3. Update documentation

## Sources

- [OpenCode Official Site](https://opencode.ai/)
- [OpenCode GitHub (sst/opencode)](https://github.com/sst/opencode)
- [OpenCode Nix Flake](https://github.com/AodhanHayter/opencode-flake)
- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server)
- [OpenCode Plugins Documentation](https://opencode.ai/docs/plugins/)
- [OpenCode MCP Servers](https://opencode.ai/docs/mcp-servers/)
- [Auto-Claude GitHub](https://github.com/AndyMik90/Auto-Claude)
- [OrbStack Documentation](https://docs.orbstack.dev/)
- [Claude Code OTEL Monitoring](https://signoz.io/blog/claude-code-monitoring-with-opentelemetry/)
