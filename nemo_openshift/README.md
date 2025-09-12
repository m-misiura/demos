## Deploy the nemo server

```
oc apply -f config.yaml
```

within the config.yaml, make sure to set the correct URL for the LLM service.

You can also adjust the guardrails; in this example, we have custom actions being triggered for forbidden content

Then deploy the server:

```
oc apply -f nemo_server_deployment.yaml
```

## Send a request

Get route

```bash
NEMO_ROUTE=$(oc get routes nemo-guardrails  -o jsonpath='{.spec.host}')
```

### Trigger the competitor guardrail

```bash
curl -X POST "http://$NEMO_ROUTE/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"How does this compare to ChatGPT?"}]}' | jq
```

this should return

```
{
  "messages": [
    {
      "role": "assistant",
      "content": "I can't answer questions about closed source AI models"
    }
  ]
}
```

### Trigger the message too long guardrail

```
curl -X POST "http://$NEMO_ROUTE/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"'"$(yes 'word' | head -n 101 | tr '\n' ' ')"'"}]}' | jq
```

this should return

```
{
  "messages": [
    {
      "role": "assistant",
      "content": "That's too long! Please shorten your message considerably."
    }
  ]
}
```
