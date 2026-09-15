---
name: grafana-panel-render-var-prefix
description: "get_panel_image variables map goes into the URL verbatim, so keys need the var- prefix or the render silently uses saved defaults"
metadata:
  node_type: memory
  type: reference
---

`mcp__grafana__get_panel_image` copies the `variables` map into the render URL as-is. Keys must
carry Grafana's `var-` prefix — `{"var-repository": "x"}`, not `{"repository": "x"}`.

**Why:** without the prefix Grafana ignores the parameter and falls back to the dashboard's *saved*
`current` value. On a dashboard whose repository variable was saved as `""`, every panel rendered
org-wide instead of per-repository — the numbers looked entirely plausible but answered a different
question (a 53.2 "active PRs" figure where the repository's own value was 7.36). No error, no
warning.

**How to apply:** always prefix, and sanity-check one render against a known value before trusting a
batch of them. Related: [[verify-before-claiming-done]].
