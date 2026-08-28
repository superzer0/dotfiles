# Claude Code setup

The portable half of my `~/.claude` configuration: sandbox settings, hooks, the
worktree policy, a starter memory set, and the list of skills I install. Every
company-specific host, path, repo name and identifier has been stripped —
placeholders are marked `example.com` or `None configured`.

## Install

Copy the standalone files:

```sh
mkdir -p ~/.claude/rules
cp rules/*.md   ~/.claude/rules/
cp scripts/*.sh ~/.claude/
cp RTK.md       ~/.claude/
chmod +x        ~/.claude/*.sh
```

Then merge, by hand, into whatever you already have:

- **`settings.json`** → `~/.claude/settings.json`. Merge key by key. Copying it
  over an existing file discards your current config.
- **`CLAUDE.md`** → `~/.claude/CLAUDE.md`. It is a single `@RTK.md` import line;
  append it, don't overwrite your global instructions.

**Replace every `/home/YOUR_USER` in `settings.json` with your home directory.**
Claude Code does not expand `~` in `sandbox.filesystem.allowWrite` — the paths
pass through a normaliser that only strips a trailing `/**`. An unexpanded path
grants nothing and fails later as a permission error that never mentions the
sandbox.

The memory files go under `~/.claude/projects/<project-slug>/memory/`, where the
slug is your project directory with `/` replaced by `-` (e.g. `-home-me-repo`).
`MEMORY.md` is the index loaded every session; one line per memory, no bodies.

Requires `jq` (both hook scripts parse their stdin with it).

## What each piece does

### `settings.json`

| Key | Why it's here |
|---|---|
| `permissions.allow` | Pre-approves the read-only verification tools I run constantly: `terraform`, `helm`, `dotnet`, `pwsh`, `make`, `kubeconform`. Nothing here mutates remote state. |
| `hooks.PreToolUse` (Bash) | Routes every Bash call through `rtk`, a token-trimming CLI proxy — see `RTK.md`. Drop this block if you don't use it. |
| `hooks.PreToolUse` (Edit\|Write) | The worktree guard. See below. |
| `statusLine` | `scripts/statusline-command.sh` — dir, model, context %, session cost, 5h/7d rate-limit headroom, session id, git dirty marker. All from the JSON the harness pipes in; no personal paths. |
| `effortLevel` / `advisorModel` | `xhigh` and `opus`. Expensive by default, on purpose. |
| `autoMode` | Auto-approval policy. Discussed below — **you must fill this in.** |
| `sandbox` | Discussed below. |

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

`allowedDomains` ships only the generally useful public hosts — GitHub, the
Terraform registry, HashiCorp releases, `*.github.io` (Helm chart repos), NuGet.
Replace `your-internal-host.example.com` with your own, or delete it.

`filesystem.allowWrite` covers the tool caches that break when they can't write:
`~/.terraform.d`, `~/.tflint.d`, `~/.nuget`, `~/.dotnet`, the three Helm
directories, plus `~/repo/claude-worktrees` for the worktree policy. Note that
the sandbox allows writes *inside* a listed directory but does not let a tool
*create* it — `mkdir` those once by hand.

Two known rough edges, unfixed: a `.NET` test run needs `-m:1` and
`MSBUILDDISABLENODEREUSE=1` because MSBuild's multi-process nodes fail under the
sandbox with `Unknown socket error`; and an IPv6-only host behind a CDN may be
unreachable through the proxy even when allowlisted.

### `autoMode.environment` — fill this in

This block is the least-known thing in the whole file and the most worth having.
It is free text the auto-approval classifier reads to decide what counts as
sensitive *in your environment*: which domains are internal, which registries are
trusted, which namespaces are production. Every value here ships as
`None configured`. JSON has no comments, so: go through the list once and replace
the entries that apply to you. An empty block means the classifier falls back to
generic heuristics — safe, but it will second-guess routine work.

`soft_deny` takes `"$defaults"` plus your own rules, e.g.

```
"Bash(az group delete:*) scoped to any resource group containing prod/production"
```

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
- **`worktree-guard.sh`** — the `PreToolUse` hook that makes the policy real. It
  denies `Edit`/`Write`/`NotebookEdit` anywhere under `$CLAUDE_REPO_ROOT` that
  isn't inside `claude-worktrees/`, and the denial message tells the agent the
  three commands to recover. A rule without a hook gets forgotten around turn 40.
- **`statusline-command.sh`** — the status line.

Both worktree scripts read `CLAUDE_REPO_ROOT` and fall back to `$HOME/repo`.

### `memory/`

Eight starter memories. Four are working preferences (draft PRs, edit the PR body
rather than commenting, delegate coding to cheaper subagents, publish research as
Artifacts), one restates the worktree policy for the memory system, and three are
reference facts that cost real time to learn: the GitHub Actions `$/` syntax, the
Grafana `folderUid` trap, and Loki stream labels vs. structured metadata.

Keep them one fact per file. The `description` line is what gets matched during
recall, so make it specific.

### `skills.md`

The 16 skills I install, with their upstream repos. Bodies are not vendored — see
that file for why.

## Caveats

- `settings.json` is a merge target, not a drop-in, and every `/home/YOUR_USER`
  in it must be replaced before it does anything.
- The `worktree-guard.sh` path in `hooks` is the one to get right first: a hook
  whose command doesn't resolve fails open, and the guard silently stops
  guarding.
