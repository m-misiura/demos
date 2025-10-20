## Deploy LLM

0. Apply the storage container

```bash
oc apply -f llm_storage.yaml
```

1. Choose either authenticated or non-authenticated deployment, and either CPU or GPU deployment, and apply the corresponding YAML file, e.g. for authenticated GPU deployment:

```bash
oc apply -f oauth/llm_gpu.yaml
```

## Sample requests

Get the route:

```bash
LLM_ROUTE=$(oc get routes llm-route -o jsonpath='{.spec.host}')
```

- Make a sample request to the chat/completion endpoint

```bash
curl -X POST "https://$LLM_ROUTE/v1/chat/completions" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llm",
    "messages": [
      {
        "role": "user",
        "content": "Hello, how would you make a delicious espresso?"
      }
    ]
  }'
```
