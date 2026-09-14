---
name: sandbox-netns-is-loopback-only
description: "Docker daemon is reachable from sandboxed Bash over its unix socket, but the bwrap netns has only lo, so no published port or container IP is reachable — integration tests using localhost must run unsandboxed"
metadata:
  node_type: memory
  type: reference
---

The Bash sandbox runs under `bwrap` in its own network namespace holding only `lo`
(`ip -o addr show` shows nothing else; `/proc/1/comm` is `bwrap`). Consequences:

- The Docker **daemon** is reachable: `/var/run/docker.sock` is bind-mounted, so `docker info`,
  `docker run`, `docker build` and `docker compose` all work sandboxed.
- Docker **containers** are not reachable over TCP. A probe container published on 18099 showed
  `docker port` → `0.0.0.0:18099`, while sandboxed `ss -ltn` listed no such listener and
  `curl http://127.0.0.1:18099/` failed to connect in 0 ms. The same curl run unsandboxed connected,
  and unsandboxed `ss -ltn` showed `LISTEN *:18099`. The container's bridge IP (172.17.0.2) is
  equally unreachable — no veth, no docker0 route.
- Loopback itself is not blocked: a `python3 -m http.server` bound on 127.0.0.1 inside the same
  sandboxed command answered 200.

This is not an egress-proxy matter — no `<sandbox_violations>` block appears and no `allowedDomains`
entry can fix it. Whether a host-loopback passthrough setting exists is unchecked; `/sandbox` is
where to look.

Related: sandboxed Roslyn/MSBuild tooling fails the same way for a different reason — the BuildHost's
`NamedPipeServerStream` bind returns `SocketException (0xFFFDFFFE) Unknown socket error`, so
`csharp-ls --diagnose` cannot load a solution sandboxed but succeeds unsandboxed.

**Why:** an integration-test fixture that reaches its stack at `http://localhost:<port>` can never
pass from sandboxed Bash — the failure looks like a broken fixture rather than a namespace with no
route.

**How to apply:** Run container-dependent test suites with `dangerouslyDisableSandbox: true`, after
asking — a compose-up is not the read-only retry the sandbox rules allow. Alternative without the
override: run the test process inside a container on the compose network so it uses service names.
