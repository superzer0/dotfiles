---
name: delegate-coding-to-lower-model-subagents
description: User wants coding tasks run in subagents on a lower-power model chosen by my judgment
metadata:
  node_type: memory
  type: feedback
---

For all coding tasks, use your own judgment to pick an appropriate lower-power model (e.g. sonnet for routine implementation, haiku for trivial mechanical edits) and run the work in a subagent via the Agent tool with a `model` override, rather than coding inline on the main-loop model.

**Why:** conserve main-loop model usage for reasoning and orchestration; cheaper models are sufficient for most implementation work.

**How to apply:** when a task involves writing or editing code, spawn a subagent with `model: "sonnet"` (default) or `model: "haiku"` (trivial edits); keep review, planning, and judgment calls in the main loop. Escalate to opus or inherit only when the coding itself is genuinely hard.
