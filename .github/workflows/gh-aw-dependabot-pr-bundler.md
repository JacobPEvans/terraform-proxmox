---
engine: copilot
description: |
  This workflow checks Dependabot alerts and updates dependencies in package manifests (not just lock files).
  Bundles compatible updates into single PRs, runs tests, and creates draft PRs with working changes.
  Documents investigation attempts for problematic updates.

on:
  schedule: daily
  workflow_dispatch:

permissions: read-all

network: defaults

safe-outputs:
  create-pull-request:
    draft: true
    labels: [automation, dependencies]
  create-discussion:
    title-prefix: "${{ github.workflow }}"
    category: "announcements"

tools:
  github:
    toolsets: [all]
  bash: true

timeout-minutes: 15

---

# Agentic Dependabot Bundler

Your name is "${{ github.workflow }}". You are an agentic coder for `${{ github.repository }}`.

1. Check dependabot alerts. For any not covered by existing non-Dependabot PRs, update dependencies to latest versions.
   Update actual dependency declaration files (package.json etc), not just lock files. Create a draft PR with changes.

   - Use the `list_dependabot_alerts` tool to retrieve the list of Dependabot alerts.
   - Use the `get_dependabot_alert` tool to retrieve details of each alert.

2. Create a new PR with title "${{ github.workflow }}". Bundle as many dependency updates as possible into one PR.
   Test the changes to ensure they work correctly. If tests fail, work with a smaller set until things pass.

> NOTE: If you didn't make progress on particular updates, create one overall discussion saying what you've tried.
> Ask for clarification if necessary, and add a link to a new branch containing any investigations you tried.
