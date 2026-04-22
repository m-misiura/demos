# Grafana Dashboard for NeMo Guardrails

Grafana instance with a pre-loaded dashboard for visualising NeMo Guardrails traces from Tempo.

## Prerequisites

- TempoStack deployed (see `../tempo/`)
- NeMo Guardrails deployed with `configmap-content.yaml` (enables guardrails-level tracing)

**Important:** The base `configmap.yaml` only produces HTTP-level spans (request latency, status codes). To see rail-level data (blocked/passed, rail names, token usage), you must use `configmap-content.yaml` which enables NeMo's built-in tracing.

## Deploy

```bash
oc apply -f grafana/
```

## Access

```bash
GRAFANA_ROUTE=$(oc get route grafana -o jsonpath='{.spec.host}')
echo "https://$GRAFANA_ROUTE"
```

Open the URL and navigate to Dashboards > NeMo Guardrails.
