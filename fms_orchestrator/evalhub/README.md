## Apply the release bundle

```bash
oc apply -f trustyai_bundle.yaml -n redhat-ods-applications
```

## Create a new namespace for the EvalHub

```bash
export NAMESPACE=evalhub-fms
oc new-project $NAMESPACE
```

## Setup detector

```bash
oc apply -f detector.yaml 
```

## Setup llm 

```bash
oc apply -f llm.yaml
```

## Setup fms orchestrator

```bash
envsubst '${NAMESPACE}' < fms.yaml | oc apply -f -
```

## Setup evalhub

```bash
oc apply -f evalhub.yaml
```

## Run garak scan

0. to run garak scan with the follwing three owasp probes (`dan.Dan_11_0`, `promptinject.HijackKillHumans`, `encoding.InjectBase64`), execute the following command:

```bash
export TOKEN=$(oc whoami -t)
export EVALHUB_URL=$(oc get route evalhub -o jsonpath='{.spec.host}')
```

```bash
curl -X POST "https://$EVALHUB_URL/api/v1/evaluations/jobs" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant: $NAMESPACE" \
  -H "Content-Type: application/json" \
  -d @evals/owasp-subset.json | jq .
```

ensure to change `url` and `uri` in `evals/owasp-subset.json` to point to the correct endpoint 

1. to quickly check the results of the scan, execute the following command:

```
export JOB_ID=<your job id>
```

```bash
curl "https://$EVALHUB_URL/api/v1/evaluations/jobs/$JOB_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant: $NAMESPACE" | jq '.results'
```