# Claude Code setup

The portable half of my `~/.claude` configuration: sandbox settings, four hooks,
the worktree policy, a maintenance layer, a starter memory set, and the list of
skills I install. Every company-specific host, path, repo name and identifier has
been stripped — placeholders are marked `example.com`, `YOUR_USER` or
`None configured`.

## Install

Copy the standalone files:

```sh
mkdir -p ~/.claude/rules ~/.claude/hooks/tests
cp rules/*.md         ~/.claude/rules/
cp hooks/*.sh         ~/.claude/hooks/
cp hooks/tests/*.sh   ~/.claude/hooks/tests/
cp scripts/*.sh       ~/.claude/
cp RTK.md             ~/.claude/
chmod +x ~/.claude/hooks/*.sh ~/.claude/*.sh
```

Then merge, by hand, into whatever you already have:

- **`settings.json`** → `~/.claude/settings.json`. Merge key by key. Copying it
  over an existing file discards your current config.
- **`CLAUDE.md`** → `~/.claude/CLAUDE.md`. It starts with an `@RTK.md` import
  line; append the rest, don't overwrite your global instructions.

**Replace every `/home/YOUR_USER` in `settings.json` with your home directory.**
Claude Code does not expand `~` in `sandbox.filesystem.allowWrite` — the paths
pass through a normaliser that only strips a trailing `/**`. An unexpanded path
grants nothing and fails later as a permission error that never mentions the
sandbox.

Verify the hooks before trusting them:

```sh
HOOKS_DIR=~/.claude/hooks bash ~/.claude/hooks/tests/hooks.test.sh
```

46 cases over the three Bash hooks (`merge-guard`, `cred-guard`, `rtk-hook`),
exit 0 = all good. `worktree-guard.sh` is not covered — test it by hand, by
trying an edit in a main checkout and again in a worktree. Re-check after any
edit to a guard: one that silently stops guarding is worse than no guard.

The memory files go under `~/.claude/projects/<project-slug>/memory/`, where the
slug is your project directory with `/` replaced by `-` (e.g. `-home-me-repo`).
`MEMORY.md` is the index loaded every session; one line per memory, no bodies.

Requires `jq` (every hook parses its stdin with it). `rtk-hook.sh` additionally
requires [rtk](RTK.md); drop that hook if you don't use it.

## What each piece does

### `settings.json`

| Key | Why it's here |
|---|---|
| `permissions.allow` | Pre-approves read-only verification commands only — `terraform plan/validate/show`, `helm template/lint`, `git log/diff/status/show`, `gh pr/run view/list`, `tflint`, `actionlint`, `kubeconform`. Nothing here mutates local or remote state. |
| `permissions.deny` | `gh pr merge` in every spelling, and reads of `~/.ssh`. Deny always wins, including over a hook's allow. |
| `permissions.ask` | Always prompt for `terraform apply/destroy/state rm/mv`, `az * delete`, `kubectl delete`, `helm uninstall`. |
| `hooks.PreToolUse` (Bash) | `merge-guard.sh`, `cred-guard.sh`, `rtk-hook.sh` — see below. |
| `hooks.PreToolUse` (Edit\|Write) | The worktree guard. See below. |
| `statusLine` | `hooks/statusline-command.sh` — dir, model, context %, session cost, 5h/7d rate-limit headroom, session id, git dirty marker. All from the JSON the harness pipes in; no personal paths. |
| `effortLevel` / `advisorModel` | `xhigh`, and `fable` for the advisor. Expensive by default, on purpose. `modelSettings` drops Sonnet to `high`. |
| `attribution` | Both fields empty — no `Co-Authored-By` trailer, no PR attribution block. (The old `includeCoAuthoredBy` key is deprecated.) |
| `env.CLAUDE_CODE_SUBAGENT_MODEL` | Subagents run on Sonnet; the main loop stays on Opus. |
| `autoMode` | Auto-approval policy. Discussed below — **you must fill `environment` in.** |
| `sandbox` | Discussed below. |

Not exported: the `SessionStart` preflight hook. It loads a driver from a private
plugin, so the wrapper would resolve to nothing on any other machine.

### Sandbox — the two settings that took real debugging

```json
"allowAllUnixSockets": true,
"strictAllowlist": false
```

**`allowAllUnixSockets: true`** — without it, `terraform validate` fails. Terraform
providers are separate processes that talk to the CLI over a go-plugin handshake
on a Unix socket; the sandbox blocks that by default and the error does not
mention sockets. Anything else with a local plugin or daemon protocol will hit
the same wall.

**`strictAllowlist: false`** — with strict on, every new host is a fresh denial
to diagnose and add. Across a wide toolchain (registries, chart repos, package
feeds, docs sites) that becomes unmanageable, and the failure mode is a confusing
error rather than a prompt. Off is the pragmatic setting; the `allowedDomains`
list still steers the proxy.

`allowedDomains` ships only generally useful public hosts — GitHub, the Terraform
registry, HashiCorp releases, `*.github.io` (Helm chart repos), NuGet, and the
Azure login/management/storage/ACR endpoints. Replace
`your-internal-host.example.com` with your own, or delete it.

`filesystem.allowWrite` covers the tool caches that break when they can't write:
`~/.terraform.d`, `~/.tflint.d`, `~/.nuget`, `~/.dotnet`, the three Helm
directories, the `act`/`gh`/`docker` caches, plus `~/repo` and
`~/repo/claude-worktrees` for the worktree policy. Note that the sandbox allows
writes *inside* a listed directory but does not let a tool *create* it — `mkdir`
those once by hand.

`denyRead` blocks `~/.ssh` at the OS level, with only the two public keys allowed
back. Do not add credential files to a `Read(...)` deny rule instead: Claude Code
merges those into the same OS-level deny, which breaks the CLI that owns the file.
That is what `cred-guard.sh` exists to work around.

Two known rough edges, unfixed: a `.NET` test run needs `-m:1` and
`MSBUILDDISABLENODEREUSE=1` because MSBuild's multi-process nodes fail under the
sandbox with `Unknown socket error`; and the sandbox network namespace has only
`lo`, so nothing on a published container port is reachable — see
`memory/sandbox-netns-is-loopback-only.md`.

### `autoMode` — `hard_deny` ships filled in, `environment` does not

`hard_deny` carries four rules that are not negotiable by anything said in a
session: no admin merge, no force-merge into a protected branch, no editing branch
protection to unblock a merge, and stop-and-report when a merge is blocked.
`merge-guard.sh` enforces the same rules deterministically — the classifier can be
talked around, a hook cannot.

`environment` is the least-known thing in the whole file and the most worth having.
It is free text the auto-approval classifier reads to decide what counts as
sensitive *in your environment*: which domains are internal, which registries are
trusted, which namespaces are production. Every value here ships as
`None configured`. JSON has no comments, so: go through the list once and replace
the entries that apply to you. An empty block means the classifier falls back to
generic heuristics — safe, but it will second-guess routine work.

### `hooks/`

- **`worktree-guard.sh`** — `PreToolUse(Edit|Write|NotebookEdit)`. Denies file
  changes anywhere under `$CLAUDE_REPO_ROOT` that isn't inside
  `claude-worktrees/`, and the denial message tells the agent the three commands
  to recover. A rule without a hook gets forgotten around turn 40.
- **`merge-guard.sh`** — `PreToolUse(Bash)`. Deterministic hard stop on
  `gh pr merge --admin`, on REST calls to `/pulls/*/merge` or mutating
  `/branches/*/protection` and `/rulesets`, and on a force push to
  `main`/`master`/`develop`/`release*` — including the implicit case where no
  refspec is given and the current branch is protected. Companion to
  `autoMode.hard_deny`, which only the classifier reads.
- **`cred-guard.sh`** — `PreToolUse(Bash)`. Refuses *shell reads* of gh's
  `hosts.yml`, az's MSAL caches, the docker config and the kubeconfig, while the
  CLIs that own those files keep working. A hook sees only the command text,
  which is exactly the distinction a `Read(...)` deny rule cannot make.
- **`rtk-hook.sh`** — `PreToolUse(Bash)`. Runs rtk's command rewrite but strips
  its `permissionDecision: "allow"` (rtk is an output filter, not a permission
  authority) and leaves `permissions.ask`-gated commands unrewritten so the ask
  rules still match. Drop this hook if you don't use rtk.
- **`statusline-command.sh`** — the status line.
- **`tests/hooks.test.sh`** — 46 assertions over the three Bash hooks, covering
  both the denials and the commands that must keep working. Set `HOOKS_DIR` to
  test a staged copy.

### `rules/`

Markdown in `~/.claude/rules/` is loaded into every session automatically. Two here:

- **`worktrees.md`** — repos under `~/repo` are read-only reference checkouts;
  all changes happen in a per-session worktree under `~/repo/claude-worktrees/`.
  With many parallel sessions across dozens of repos, this is what stops two
  agents from fighting over one working tree.
- **`context7.md`** — the lookup order for the Context7 docs MCP server.

### `scripts/`

- **`new-worktree.sh <repo> <topic-slug> [base-ref]`** — creates
  `$CLAUDE_REPO_ROOT/claude-worktrees/<repo>.<slug>-<session-id-prefix>` on
  branch `claude/<slug>-<session-id-prefix>` and prints the path. Idempotent:
  re-running returns the existing path.
- **`daily-maintenance.sh`** — one-run-per-day wrapper (date stamp + `flock`) that
  calls the two cleanup scripts and prunes the `TMPDIR` root.
- **`fetch-prune-repos.sh`** — daily `git fetch --prune` across every checkout, so
  `: gone]` branches are findable.
- **`stale-worktree-cleanup.sh`** — removes worktrees idle 7+ days, but **skips and
  logs** anything dirty or with an open PR. It aborts outright when `gh` is not on
  `PATH` rather than deleting without the open-PR check.
- **`worktree-layout-audit.sh`** — weekly, report-only: stray session dirs and
  worktrees outside the canonical directory.
- **`crontab.example`** — how the above get scheduled, including the `PATH=` line
  that keeps the open-PR guard alive under cron.

The worktree scripts read `CLAUDE_REPO_ROOT` and fall back to `$HOME/repo`.

### `memory/`

Fourteen starter memories. Four are working preferences (draft PRs, edit the PR
body rather than commenting, delegate coding to cheaper subagents, publish
research as Artifacts), one restates the worktree policy for the memory system,
and the rest are tool facts that each cost real time to learn: the GitHub Actions
`$/` syntax, the Grafana `folderUid` trap, Loki stream labels vs. structured
metadata, why `gh pr checks` exit 0 is not CI-green, why overnight cron never
fires in WSL, the two ways the worktree guard blocks harmless commands, and the
loopback-only sandbox namespace.

Keep them one fact per file. The `description` line is what gets matched during
recall, so make it specific.

### `skills.md`

The 17 skills I install, with their upstream repos. Bodies are not vendored — see
that file for why.

## macOS notes

Bootstrapped on macOS 26 (Tahoe, arm64). Differences from the Linux instructions
above:

- **Paths.** `settings.json` ships `/home/YOUR_USER`; on macOS that is
  `/Users/<you>`. The same caveat applies — Claude Code does not expand `~` in
  `sandbox.filesystem.allowWrite`, and an unexpanded path grants nothing.
- **`realpath -m`.** BSD `realpath` has no `-m`, so on stock macOS the
  `realpath -m` call in `hooks/worktree-guard.sh` failed and, because the line
  ends `|| exit 0`, the hook exited 0 and **the guard silently stopped guarding**.
  It now prefers `grealpath` (Homebrew `coreutils`, added to the `Brewfile`) and
  falls back to a pure-shell normaliser, so it works with or without coreutils.
- **Homebrew 7 tap trust.** Third-party taps must be trusted explicitly before
  `brew bundle` will load a formula from them:
  `brew trust --formula hashicorp/tap/terraform`. Untrusted taps are skipped
  with a warning, and `brew bundle` can exit 0 having installed nothing from
  them — check with `brew bundle check`.
- **`brew bundle --no-lock`** was removed in Homebrew 7. Passing it prints the
  usage text and **exits 0 without installing anything**.
- **rtk config path** is `~/Library/Application Support/rtk/config.toml`, not
  `~/.config/rtk/config.toml`. Relevant if these dotfiles are synced with Linux
  machines.
- **Prompt.** Use oh-my-zsh + powerlevel10k (`.p10k.zsh`), not the `oh-my-posh`
  setup in `.profile`, which is the Linux/bash path.
- **Terminal.** `ghostty/config` is a port of the iTerm2 profile
  `JakubDefault.json`. Validate with `ghostty +validate-config`.

## Caveats

- `settings.json` is a merge target, not a drop-in, and every `/home/YOUR_USER`
  in it must be replaced before it does anything.
- The hook paths in `settings.json` are the thing to get right first: a hook whose
  command doesn't resolve fails open, and the guard silently stops guarding. Run
  `hooks/tests/hooks.test.sh` after wiring them up.
