---
name: gh-pr-checks-watch-exits-zero-before-checks-register
description: "gh pr checks --watch exits 0 with \"no checks reported\" if run right after a push, so exit 0 is not CI-green proof"
metadata:
  node_type: memory
  type: feedback
---

`gh pr checks <n> --watch --fail-fast` run immediately after `git push` returns
**exit 0** with the body `no checks reported on the '<branch>' branch` — the workflow
run has not registered yet, so there is nothing to watch and it does not wait.
Exit 8 means pending; exit 0 here means "I saw nothing".

**Why:** this produced a false "CI green" report twice in one session. The other
variant of the same mistake is piping `--watch` into `tail`, which makes `$?`
tail's exit code, not gh's.

**How to apply:** never treat a `gh pr checks` exit code as the CI verdict.
Resolve the run id first (`gh run list --branch <branch> --limit 1 --json databaseId,headSha`),
confirm `headSha` matches the commit just pushed, then `gh run watch <id> --exit-status`
and finish with an authoritative
`gh run view <id> --json status,conclusion,headSha,url`. Quote that conclusion line
as the proof.
