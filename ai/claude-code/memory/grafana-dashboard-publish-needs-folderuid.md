---
name: grafana-dashboard-publish-needs-folderuid
description: POSTing a dashboard to the Grafana API without folderUid moves it to the root folder, which can lock a scoped service account out
metadata:
  node_type: memory
  type: reference
---

Every `POST /api/dashboards/db` must carry `"folderUid": "<uid>"` alongside
`"dashboard"` and `"overwrite": true`.

`GET /api/dashboards/uid/<uid>` returns the folder in `meta.folderUid`, **not**
inside `dashboard` — so a fetch-modify-publish round trip that only echoes back
the `dashboard` object silently drops it and Grafana relocates the dashboard to
the root "Dashboards" folder.

**Why it bites:** a service account with no basic role typically has
`dashboards:read` / `:write` / `:delete` scoped to specific folder UIDs, while
`dashboards:create` also includes `folders:uid:general`. That combination lets
the account move a dashboard *into* the root folder and then not read, update,
delete or render it. Recovery needs a human to move it back in the UI; the token
cannot undo it.

**How to apply:** read `meta.folderUid` from the GET response and pass it back on
the POST. Verify the response echoes the expected `folderUid`, not `""`.
