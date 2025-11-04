## Get the route

```bash
EMBEDDING_ROUTE=$(oc get routes embedding-detector-route -o jsonpath='{.spec.host}')
```

## Make a request

```bash
curl -v -X POST \
  "https://${EMBEDDING_ROUTE}/openai/v1/embeddings" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "embedding-detector",
    "input": "This is an example sentence for embedding generation."
  }' | jq
```