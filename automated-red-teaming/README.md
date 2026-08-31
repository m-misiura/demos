## Automated Red Teaming Pipeline

Automated risk assessment on OpenShift AI 3.4 using [EvalHub](https://github.com/eval-hub/eval-hub) to orchestrate [NVIDIA Garak](https://github.com/NVIDIA/garak) via Kubeflow Pipelines.

The pipeline runs two evaluations: a **baseline** scan against the raw target model, then a **guarded** scan against the same model fronted by NeMo Guardrails with HAP and prompt injection detectors. Comparing the Attack Success Rate (ASR) between the two quantifies the guardrail uplift.

> **Technology Preview** -- automated risk assessment is a Technology Preview feature in RHOAI 3.4.

### Prerequisites

- Red Hat OpenShift AI 3.4+ with TrustyAI enabled
- 2x GPUs (one for target model, one for challenger)
- `oc` CLI authenticated to the cluster
- A HuggingFace token

---

### Setup

#### 1. Namespace and models

```bash
oc new-project evalhub

# Target model (OCI modelcar, no download needed)
oc apply -f target-model.yaml

# Challenger model (abliterated Llama 3.2 1B -- judge + SDG)
vi hf-token-secret.yaml  # set your HF token
oc apply -f hf-token-secret.yaml
oc apply -f challenger-model-pvc.yaml
oc apply -f challenger-model-download.yaml
oc logs -f job/download-challenger-model  # wait for completion

oc apply -f challenger-model.yaml
oc wait llminferenceservice/target-model challenger-model --for=condition=Ready --timeout=600s
```

#### 2. Data Science Pipelines

```bash
oc apply -f dspa.yaml
oc wait dspa/dspa --for=condition=Ready --timeout=300s
```

#### 3. Patch provider ConfigMap (S3 credentials for adapter pod)

The Garak adapter pod needs MinIO credentials to download scan results. Add S3 env vars to the provider ConfigMap **before** deploying EvalHub.

```bash
oc get configmap trustyai-service-operator-evalhub-provider-garak-kfp \
  -n redhat-ods-applications \
  -o jsonpath='{.data.garak-kfp\.yaml}' > /tmp/garak-kfp.yaml
```

Add to the `runtime.k8s.env` section in `/tmp/garak-kfp.yaml`:

```yaml
      - name: AWS_ACCESS_KEY_ID
        value: "minio"
      - name: AWS_SECRET_ACCESS_KEY
        value: "minio123"
      - name: AWS_S3_ENDPOINT
        value: "http://minio-dspa.evalhub.svc.cluster.local:9000"
      - name: AWS_DEFAULT_REGION
        value: "us-east-1"
```

Apply and restore provider labels (`oc apply` drops labels):

```bash
oc create configmap trustyai-service-operator-evalhub-provider-garak-kfp \
  --from-file=garak-kfp.yaml=/tmp/garak-kfp.yaml \
  -n redhat-ods-applications --dry-run=client -o yaml | oc apply -f -

oc label configmap trustyai-service-operator-evalhub-provider-garak-kfp \
  trustyai.opendatahub.io/evalhub-provider-name=garak-kfp \
  trustyai.opendatahub.io/evalhub-provider-type=system \
  app.kubernetes.io/part-of=trustyai \
  -n redhat-ods-applications --overwrite
```

#### 4. EvalHub

```bash
oc apply -f postgres.yaml
oc apply -f evalhub-db-credentials.yaml
oc wait deployment/postgresql --for=condition=Available --timeout=120s
oc apply -f evalhub-cr.yaml
oc wait evalhub/evalhub --for=condition=Ready --timeout=300s
```

#### 5. RBAC and secrets

```bash
NS=$(oc project -q)

# Allow adapter pod to submit pipelines through DSPA kube-rbac-proxy
oc create role evalhub-job-dspa-access \
  --verb=get,list,watch,create,update,patch,delete \
  --resource=datasciencepipelinesapplications/api
oc create rolebinding evalhub-job-dspa-access \
  --role=evalhub-job-dspa-access \
  --serviceaccount="${NS}:evalhub-evalhub-job"

# API key secret (dummy -- models have auth disabled)
oc create secret generic model-api-keys --from-literal=API_KEY="dummy"
```

---

### Phase 1: Baseline scan

Run the evaluation directly against the unguarded target model.

```bash
NS=$(oc project -q)
TOKEN=$(oc whoami -t)
EVALHUB_URL="https://$(oc get routes evalhub -o jsonpath='{.spec.host}')"

SA_TOKEN=$(oc create token evalhub-evalhub-job --duration=24h)

jq --arg token "$SA_TOKEN" \
  '.benchmarks[0].parameters.kfp_config.auth_token = $token' intents-scan.json | \
curl -s -X POST "$EVALHUB_URL/api/v1/evaluations/jobs" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Tenant: $NS" \
  -d @- | jq
```

### Phase 2: Deploy guardrails

Deploy HAP and prompt injection detectors, then the NeMo Guardrails server that fronts the target model.

```bash
# Detectors (HAP defines the shared ServingRuntime)
oc apply -f nemo/hap_detector.yaml
oc apply -f nemo/prompt-injection-detector.yaml

# NeMo Guardrails config and server
oc apply -f nemo/nemo_configmap.yaml
oc apply -f nemo/nemo_server.yaml

# Wait for detectors and guardrails server
oc wait inferenceservice/detector-hap prompt-injection-detector \
  --for=condition=Ready --timeout=300s
oc wait nemoguardrails/guardrails --for=condition=Ready --timeout=300s
```

### Phase 3: Guarded scan

Run the same evaluation against the NeMo Guardrails endpoint. Garak now hits the guardrails proxy, which runs HAP and prompt injection checks before forwarding to the target model.

```bash
SA_TOKEN=$(oc create token evalhub-evalhub-job --duration=24h)

jq --arg token "$SA_TOKEN" \
  '.benchmarks[0].parameters.kfp_config.auth_token = $token' intents-scan-guarded.json | \
curl -s -X POST "$EVALHUB_URL/api/v1/evaluations/jobs" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Tenant: $NS" \
  -d @- | jq
```

### Monitor

```bash
# Watch pipeline pods
oc get workflows -w

# Check job status
curl -s "$EVALHUB_URL/api/v1/evaluations/jobs" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant: $NS" | jq
```

### Compare results

Both scans produce ASR metrics. The difference between baseline and guarded ASR is the guardrail uplift:

```bash
# List completed jobs with ASR
curl -s "$EVALHUB_URL/api/v1/evaluations/jobs" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant: $NS" | \
jq '.items[] | select(.status.state == "completed") |
  {name: .name, asr: .results.test.score,
   probes: .results.benchmarks[0].metrics}'
```

The HTML reports are stored in the DSPA MinIO bucket.

---

### Teardown

```bash
oc delete nemoguardrails guardrails --ignore-not-found
oc delete inferenceservice detector-hap prompt-injection-detector --ignore-not-found
oc delete servingruntime guardrails-detector-runtime --ignore-not-found
oc delete evalhub evalhub --ignore-not-found
oc delete workflows --all
oc delete llminferenceservice target-model challenger-model --ignore-not-found
oc delete job download-challenger-model --ignore-not-found
oc delete dspa dspa --ignore-not-found
oc delete deployment postgresql --ignore-not-found
oc delete svc postgresql --ignore-not-found
oc delete pvc challenger-model-pvc postgresql --ignore-not-found
oc delete secret hf-token model-api-keys dspa-s3-credentials evalhub-db-credentials --ignore-not-found
oc delete configmap guardrails-config --ignore-not-found
oc delete role evalhub-job-dspa-access --ignore-not-found
oc delete rolebinding evalhub-job-dspa-access --ignore-not-found
oc delete pods --all
```

---

### Files

| File | Purpose |
|------|---------|
| `target-model.yaml` | Target model (Granite 3.1 2B, OCI modelcar) |
| `hf-token-secret.yaml` | HuggingFace token secret |
| `challenger-model-pvc.yaml` | PVC for challenger model weights |
| `challenger-model-download.yaml` | Job to download Llama 3.2 1B abliterated from HF |
| `challenger-model.yaml` | Challenger model (judge + SDG) |
| `dspa.yaml` | Data Science Pipelines with embedded MinIO |
| `postgres.yaml` | PostgreSQL for EvalHub |
| `evalhub-db-credentials.yaml` | DB connection secret |
| `evalhub-cr.yaml` | EvalHub custom resource |
| `intents-scan.json` | Baseline risk assessment job definition |
| `intents-scan-guarded.json` | Guarded risk assessment job definition |
| `nemo/hap_detector.yaml` | HAP detector (ServingRuntime + InferenceService) |
| `nemo/prompt-injection-detector.yaml` | Prompt injection detector (InferenceService) |
| `nemo/nemo_configmap.yaml` | NeMo Guardrails configuration |
| `nemo/nemo_server.yaml` | NeMo Guardrails CR |

### References

- [Official docs: Automated risk assessment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/evaluating_ai_systems/test-model-safety-with-automated-risk-assessment_evaluate)
- [EvalHub docs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/evaluating_ai_systems/evaluating-llms-with-evalhub_evaluate)
- [Blog: Testing infrastructure red teaming with abliterated models](https://developers.redhat.com/articles/2026/05/26/testing-infrastructure-red-teaming-abliterated-models)
