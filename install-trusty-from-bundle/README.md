## Instructions

1. Set TrustyAI to `Removed` within `default-dsc`

2. Running `oc get datasciencecluster default-dsc -o jsonpath='{.spec.components.trustyai.managementState}'` should return `Removed`

3. Running `oc get pods -n redhat-ods-applications | grep trusty` should return no pods 

4. You can now install TrustyAI from the bundle, i.e. 

```bash
oc apply -f bundle.yaml -n redhat-ods-applications
```

5. Verify the installation by checking `oc get pods -n redhat-ods-applications | grep trusty`; you should see a running pod

```bash
trustyai-service-operator-controller-manager-bc859c56d-8llwp      1/1     Running   0               5d15h
```

6. You can check which images are being used by the operator

```bash
oc get configmap trustyai-service-operator-config -n redhat-ods-applications -o jsonpath='{.data}' | jq .
```

this might return something like:

```json
{
  "evalHubImage": "quay.io/evalhub/evalhub:latest",
  "evalhub-provider-garak-image": "quay.io/evalhub/garak:latest",
  "evalhub-provider-guidellm-image": "quay.io/evalhub/community-guidellm:latest",
  "evalhub-provider-lighteval-image": "quay.io/evalhub/community-lighteval:latest",
  "evalhub-provider-lm-evaluation-harness-image": "quay.io/opendatahub/ta-lmes-job:odh-3.4-ea2",
  "garak-provider-image": "quay.io/trustyai/llama-stack-provider-trustyai-garak:latest",
  "guardrails-built-in-detector-image": "quay.io/trustyai/guardrails-detector-built-in:latest",
  "guardrails-orchestrator-image": "quay.io/trustyai/ta-guardrails-orchestrator:latest",
  "guardrails-sidecar-gateway-image": "quay.io/trustyai/guardrails-sidecar-gateway:latest",
  "kServeServerless": "enabled",
  "kube-rbac-proxy": "quay.io/openshift/origin-kube-rbac-proxy:4.19",
  "lmes-allow-code-execution": "true",
  "lmes-allow-online": "true",
  "lmes-default-batch-size": "8",
  "lmes-detect-device": "true",
  "lmes-driver-image": "quay.io/trustyai/ta-lmes-driver:latest",
  "lmes-image-pull-policy": "Always",
  "lmes-max-batch-size": "24",
  "lmes-pod-checking-interval": "10s",
  "lmes-pod-image": "quay.io/trustyai/ta-lmes-job:latest",
  "nemo-guardrails-image": "quay.io/rh-ee-mmisiura/nemo-guardrails:lates_sync",
  "oauthProxyImage": "registry.redhat.io/openshift4/ose-oauth-proxy-rhel9@sha256:b6236d488879f13bb9ed45c5363c6aae63d87672fa3c8789a7c9bbb95d25a9e4",
  "trustyaiOperatorImage": "quay.io/trustyai/trustyai-service-operator:latest",
  "trustyaiServiceImage": "quay.io/trustyai/trustyai-service:latest"
}
```

7. You can also swap out an image

```bash
oc patch configmap trustyai-service-operator-config -n redhat-ods-applications --type='json' -p='[{"op": "replace", "path": "/data/nemo-guardrails-image", "value": "quay.io/rh-ee-mmisiura/nemo-guardrails:models-endpoint"}]'
```