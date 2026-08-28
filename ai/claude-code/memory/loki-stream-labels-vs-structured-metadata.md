---
name: loki-stream-labels-vs-structured-metadata
description: In Loki, only real stream labels work inside {}; structured metadata returns zero streams there and must be filtered after a pipe
metadata:
  node_type: memory
  type: reference
---

`list_loki_label_names` returns both **stream labels** and **structured
metadata**, with nothing marking which is which. Only stream labels work inside
`{}`. A selector like `{service_name="x", service_instance_id=~".+"}` returns
zero streams — silently, as an empty panel, not as an error.

Apply structured metadata after the selector instead:

```logql
{service_name="$service"} | deployment_environment_name=~"$env" | service_instance_id=~"${instance:regex}"
```

With OpenTelemetry ingestion the split usually lands as:

- **stream labels** — `service_name`, `severity_text`, and the `k8s_*` topology
  labels (`namespace`, `deployment`, `cluster`)
- **structured metadata** — `trace_id`, `span_id`, `service_version`,
  `service_instance_id`, `k8s_pod_name`, `deployment_environment_name`,
  `scope_name` (the logger category), `detected_level`, plus per-message
  properties

Verify against your own tenant before building panels on it.

**Two matcher facts, verified:** `=~".*"` matches lines where the field is
absent (Prometheus semantics), so a dashboard variable's `allValue=".*"` works;
`=~".+"` matches only lines that carry the field.

**Dead ends, tested:** grouping by `_OriginalFormat_` (the message template)
always yields an empty label, with `{{._OriginalFormat_}}` and
`{{ index . "_OriginalFormat_" }}` alike. `/loki/api/v1/patterns` returns 404
unless the pattern ingester is enabled.
