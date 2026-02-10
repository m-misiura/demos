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

# Version 0.19

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

# Version 0.20

### Trigger the competitor guardrail

```bash
curl -X POST "http://$NEMO_ROUTE/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-config-name",
    "messages": [{"role":"user","content":"How does this compare to ChatGPT?"}]
  }' | jq
```

this should return

```json
{
  "id": "chatcmpl-6c8e134f-36fd-4653-982b-9e5d3d52f4bf",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "I can't answer questions about closed source AI models",
        "role": "assistant"
      }
    }
  ],
  "created": 1770733992,
  "model": "your-config-name",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "rails-custom-action"
  }
}
```

### Trigger the message too long guardrail

```bash
curl -X POST "http://$NEMO_ROUTE/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "abc",
    "messages": [{"role":"user","content":"'"$(yes 'word' | head -n 101 | tr '\n' ' ')"'"}]
  }' | jq
```

this should return

```json
{
  "id": "chatcmpl-f3b112d6-6218-4659-9c55-46f79231bac4",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "That's too long! Please shorten your message considerably.",
        "role": "assistant"
      }
    }
  ],
  "created": 1770734108,
  "model": "abc",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "rails-custom-action"
  }
}
```