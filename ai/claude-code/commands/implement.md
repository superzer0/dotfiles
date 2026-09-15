---
description: Implement an agreed plan in a subagent, then verify it independently in the main thread
argument-hint: [plan file path or one-line summary]
---

Implement the plan: $ARGUMENTS

If the argument is a path, read that file. If it is empty, use the plan already agreed in this
conversation. The plan is final — do not brainstorm or re-plan it.

## Constraints

These bind every step, and every agent this command spawns.

**Never weaken a check to make it pass.** No deleting, skipping or `xit`-ing a test, no lowered
coverage or quality threshold, no removed assertion, no `continue-on-error`, `|| true`,
`-ErrorAction SilentlyContinue`, `--no-verify`, new lint-ignore entry or widened `kubeconform` skip.
This also covers the CI definition itself: no removing or narrowing the job/step/trigger in
`.github/workflows/*` that runs the check validating this change, no shrinking its matrix, no
dropping it from required status checks — the agent that wrote the change does not get to edit the
check grading it. A red check is information. If the check itself is genuinely wrong, stop and tell
me — that call is mine, not yours.

**Never bypass a gate.** No admin or force merge, no branch-protection change, no editing
`settings.json` or a guard hook to get past a denial. If something is blocked, stop and report it.

**Stop on destructive infrastructure.** A `terraform plan` that destroys or replaces a stateful
resource — storage, SQL, Key Vault, anything holding data — ends the loop and comes to me with the
plan output. Where merge to main auto-applies, there is no undo.

**Stay inside the plan.** No drive-by refactor, reformat, version bump, or dependency addition. If a
file needs one line changed, change one line. A real problem found outside the plan gets reported,
not fixed.

**Do not rewrite published history or leak secrets.** No force-push to a branch with an open PR. No
credential, token or connection string in a commit, a log line, or a PR body.

**UNVERIFIED is an acceptable answer.** Never present an unrun check as passing. A check may be
re-run without a code change exactly once, only for an infrastructure flake (runner timeout, network
error), and the re-run must be stated.

## 1. Worktree

`git fetch origin`, then `bash ~/.claude/new-worktree.sh <repo-dir-name> <topic-slug>`,
then `EnterWorktree` with `path:` set to the printed path. The subagent inherits this working
directory, so enter it before spawning. Never spawn with `isolation: "worktree"`. Never edit the main
checkout in place — every step below happens inside this worktree.

## 2. Subagent implements

Spawn one `general-purpose` agent with `model: sonnet` (`haiku` for one or two mechanical edits).
Record the agent ID from the tool result.

Its prompt must contain: the plan text verbatim; the Constraints section above, verbatim; "update
README.md, CLAUDE.md and AGENTS.md in every touched repo where the change affects what that file
documents"; "commit on the current branch with SSH signing (`git commit -S`), do not push"; "write
every intermediate file under `$TMPDIR`, never `/tmp`"; the name of the domain skill it must invoke
before editing (same routing as step 4 — for a Terraform repo that might be
`platform-terraform:platform-terraform`); and this report shape.

If SSH signing fails, do not deny or work around `~/.ssh` reads to get past it — report the exact
error and stop; the fix is an agent config issue, not a permission to bypass.

**It must prove the change works — a claim with no evidence attached does not count as done.** Every
numbered claim carries the command it ran and the decisive lines of that command's output: the test
that now passes, the `terraform plan` stanza, the `helm template` fragment, the `actionlint` clean
exit. Where the plan changes behaviour that nothing currently exercises, it writes the smallest check
that would fail without the change, and shows it failing before and passing after. A claim it could
not prove is reported as unproven, with the reason. Guessing is a worse outcome than an honest gap.

If it errors out or stalls, `SendMessage` to that agent ID with the exact error and let it resume.
Start a fresh agent only if the ID is gone, and say so in the reply.

## 3. Verify without trusting the report

Derive the file list yourself — `git diff --name-only <base>...HEAD` plus `git status --porcelain`
for untracked files. Never reuse the subagent's list. `cat` every file in it. Anything in the diff
the plan did not ask for is a finding, not a bonus.

Then run what the change type demands:

- Grafana dashboard JSON → render the FULL dashboard image and inspect it
- Terraform repo → `terraform plan`, keep the output
- Helm chart → `helm template` + `kubeconform`
- `.github/workflows/` → `actionlint`, then `act`
- `*.ps1` → the Pester suite
- Any repo with a test suite → run it

Then re-run every command in the agent's evidence bundle yourself. VERIFIED means you ran it and got
the same decisive line; a bundle entry you did not reproduce is UNVERIFIED no matter how convincing
the quoted output looks.

Print a table: one row per numbered claim, marked VERIFIED with the command and the decisive line of
output, or UNVERIFIED. Claims that need a live cluster or a deployed environment stay UNVERIFIED.

## 4. Review

Take every row the diff matches — generic review misses what a domain skill catches for free.
Everything here is read-only, so nothing collides with the worktree, but the two kinds dispatch
differently: check which table a row is in.

**Agents** — one `Agent` message containing all of them, so they run in parallel:

| Change | Agent |
| --- | --- |
| Terraform repo | `platform-terraform:platform-tf-reviewer` |
| `*.ps1`, or workflow steps that can swallow errors | `pr-review-toolkit:silent-failure-hunter` |

**Skills** — the `Skill` tool, in the main thread, one after another:

| Change | Skill |
| --- | --- |
| always | `code-review` |
| non-trivial new code | `ponytail:ponytail-review` — is the simple version enough |
| Grafana dashboard or alert JSON | `grafana-core:dashboarding` |
| PromQL in a panel, alert or recording rule | `grafana-core:promql` |
| LogQL / Loki labels | `grafana-lgtm:loki` |
| alert rules, notification policy, SLO | `grafana-core:alerting-irm` |
| KQL against Azure Monitor or Log Analytics | `kql` |
| `.github/workflows/` | `github-actions-hardening`, and `github-actions-efficiency` if runner time changed |
| Azure resources in Terraform | `azure:azure-validate`, `azure:azure-reliability` |
| Entra app registration, federated credential, OIDC | `azure:entra-app-registration` |
| role assignment or RBAC scope | `azure-role-selector` |
| auth, tokens, secrets | `security-review` |
| k6 script | `grafana-k6:k6` |
| `dependabot.yml` | `dependabot` |
| Claude API, model id, agent or MCP code | `claude-api` |

The table goes stale. Before dispatching, read the session's skill list and add anything whose
description matches the diff — a domain skill that exists and was not consulted is a miss, not a
saving.

`code-review` defaults to the uncommitted diff, which is empty once the agent has committed — pass
`<base>...HEAD` or the branch name explicitly.

Do not run `pr-review-toolkit:code-simplifier` here — it edits, which reintroduces write contention.
`ponytail:ponytail-review` answers the same question and only reports.

Hand each reviewer the diff **and** the implementing agent's evidence bundle, and ask it to judge the
proof as well as the code: does the test actually fail without this change, does the plan output show
what the claim says it shows, is the check exercising the changed path or a neighbour. That is the
question reviewers answer well and the main thread answers badly — re-running a command proves it
reproduces, not that it was the right command.

A reviewer's finding is a claim like any other: confirm it against the code yourself before acting on
it, and add the confirmed ones to the same table. Never let a reviewer apply its own fix — fixes go
back to the implementing agent via `SendMessage`, then step 3 runs again on the new diff.

## 5. Ship

`git push origin HEAD` — never `-u`, never a bare `git push` — then `gh pr create --draft --head
<branch>`. The body states what changed, why, and how it was verified, using VERIFIED rows only, and
carries the story / work-item reference. Report UNVERIFIED rows to me in chat, never in the PR.

Before any `gh pr edit` — here or in step 6 — run `gh pr view <branch> --json isDraft,state -q '.'`
first. Never flip draft → ready as a side effect of an edit; if it's already ready for review, say so
instead of silently changing it back.

## 6. Hold until CI is green

The work is not done at "PR opened". Watch the run to completion:

```bash
gh pr checks <number> --watch --fail-fast
```

Run it with `run_in_background: true` — CI outlasts the Bash timeout, and the harness re-invokes you
when the command exits. Exit code 8 means checks are still pending, not that they passed.

Once every check is green, grab the run URL (`gh pr checks <number> --json name,link -q '.[].link'`
or `gh run view <run-id> --json url -q .url`) and quote it in the report as the CI-green proof.

On a failure, `gh run view <run-id> --log-failed` for the failing step. Fix it the same way as any
other change: back to the implementing agent via `SendMessage`, step 3 re-verifies the new diff, then
push again and `gh pr edit --body` to bring the description in line with what the branch now
contains. Then watch again.

CI confirms a local check; it never replaces one. If a red check was reproducible locally, say which
step 3 command should have caught it. If the same check fails twice after a fix attempt, stop and
report — that is a signal to think, not to push again.

Report the work complete only when the checks are green, quoting the step-3 verified/unverified
ledger and the CI run URL as evidence — no completion claim without them. End the reply with the
full URLs of the session's still-open PRs.
