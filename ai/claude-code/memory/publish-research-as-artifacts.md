---
name: publish-research-as-artifacts
description: Publish research and investigation findings as Artifacts, not just terminal output
metadata:
  node_type: memory
  type: feedback
---

When the deliverable is research — an investigation, an audit, a findings report, a triage of log data — publish it as an Artifact rather than leaving it in terminal scrollback.

**Why:** terminal output scrolls away and can't be handed to anyone. An Artifact is a durable page that is easy to read through and easy to share with a team.

**How to apply:** write the report as an HTML file in the scratchpad (never inside a repo where a merge auto-deploys), publish it with the Artifact tool, and hand back the link alongside a short terminal summary of the findings. Keep the same file path when updating so the URL stays stable.
