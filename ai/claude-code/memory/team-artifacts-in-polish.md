---
name: team-artifacts-in-polish
description: "Team-facing artifacts, wiki pages and instructions are written in Polish, keeping English technical terms and verbatim tool/file quotes"
metadata:
  node_type: memory
  type: feedback
---

Artifacts, wiki pages and instructions written for the user's team must be in Polish. Keep in
English: established technical vocabulary the team only ever sees in English (harness,
context/loop engineering, hook, skill, subagent, worktree, ledger, prompt, draft PR, commit status),
and anything quoted verbatim from a real file or tool — hook deny output, `CLAUDE.md` and
memory-file samples, classifier wording, error strings, commands.

**Why:** stated by the user after three English artifacts were delivered, with the explicit carve-out
not to translate terms nobody would recognise translated. The repos' own `CLAUDE.md` files are
English, so showing a Polish sample would teach the wrong convention.

**How to apply:** write prose, headings, captions, labels, speaker notes and the prompts the reader
types in Polish, with Polish quotation marks („…"). This narrows the "All text in English only" line
in `~/.claude/CLAUDE.md`, which still holds for PR titles and bodies, review comments and code
comments. See [[publish-research-as-artifacts]] and [[pr-docs-writing-style]].

*(Swap Polish for your own language, or drop this memory — it is a personal preference, not a
portable rule.)*
