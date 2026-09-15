---
name: pr-docs-writing-style
description: "PR descriptions, code comments and docs: concise, factual, English only — what changed, why, how verified"
metadata:
  node_type: memory
  type: feedback
---

PR descriptions, code comments and documentation must be concise and factual: what changed, why,
how it was verified. No chain-of-thought narration, no walls of text. All text in English only.
To change a PR's title or body, edit the PR itself (`gh pr edit`) — do not post a new comment
unless the user asked for a review comment.

**Why:** long narrated PR bodies make a reviewer reconstruct the reasoning instead of reading the
change. Chat may happen in another language; the repos and PRs are English-only.

**How to apply:** structure a PR body as change / reason / verification, three short sections.
Keep code comments to the non-obvious "why". Chat language follows the user
([[feedback-conciseness]]), file and PR content is always English. Editing over commenting is
covered in [[pr-update-description-not-comment]]; verification claims must be real
([[verify-before-claiming-done]]).
