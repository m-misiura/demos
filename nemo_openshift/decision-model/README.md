# Decision model

This deploys `Qwen/Qwen3-0.6B` as a vLLM structured-decision model using an OpenShift AI 3.6 `LLMInferenceService`.

## Deploy llm 

- create a demo namespace:

```bash
oc new-project decisions-nemo
```

- deploy `Qwen/Qwen3-0.6B`

```bash
oc apply -f decision-model.yaml -n decisions-nemo
```

## Test locally

Forward the pod port:

```bash
oc port-forward deployment/decision-model-kserve 8000:8000 
```

Call the decisions API:

```bash
curl -k https://localhost:8000/v1/decisions \
  -H "Authorization: Bearer EMPTY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "decision-model",
    "input": "The package arrived with a broken screen.",
    "questions": [
      {
        "type": "predicate",
        "name": "damaged",
        "instructions": "Does the customer report a damaged item?"
      },
      {
        "type": "choice",
        "name": "department",
        "instructions": "Which department should handle this complaint?",
        "choices": [
          {"value": "returns"},
          {"value": "billing"}
        ]
      },
      {
        "type": "score",
        "instructions": "How severe is the damage?",
        "levels": [
          {"label": "cosmetic"},
          {"label": "broken"}
        ]
      }
    ]
  }'
```

The pod serves TLS, so the localhost request uses `https` and `-k`.

## Deploy NeMo Guardrails

```bash
oc apply -f guardrails.yaml -n decisions-nemo
```

- Set the public Guardrails URL:

```bash
GUARDRAILS_URL=$(oc get route decision-guardrails -n decisions-nemo -o jsonpath='https://{.spec.host}')
```

- An in-scope shoe request reaches the main model:

```bash
curl -s "$GUARDRAILS_URL/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "decision-model",
    "messages": [
      {"role": "user", "content": "What running shoes are good for wide feet?"}
    ]
  }' | jq .
```

this yields the following response:

```json
{
  "id": "chatcmpl-8943004f-572f-4724-b573-cb486e1262ac",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "Running shoes designed for wide feet should prioritize **arch support**, **cushioning**, and **modular designs** to accommodate wider feet. Here are some top options:\n\n1. **Nike Swoosh**: Known for its wide, cushioned arch support and stability.  \n2. **Adidas Ultraboost**: Features a wide, flexible sole and good cushioning.  \n3. **Puma X**: Offers a wide footbed and responsive arch support.  \n4. **New Balance Zipline**: Ideal for wide feet with a flexible sole and good cushioning.  \n\n**Key considerations**: Choose a shoe with a **wide, flat sole** to prevent arch issues, **modular arch support** (like a midsole with a wide base), and **high cushioning** for comfort. Always check the brand’s footbed size and cushioning level.",
        "role": "assistant"
      }
    }
  ],
  "created": 1794837355,
  "model": "decision-model",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "decision"
  }
}
```

- An out-of-scope programming request is blocked by the custom action, which calls `/v1/decisions`:

```bash
curl -s "$GUARDRAILS_URL/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "decision-model",
    "messages": [
      {"role": "user", "content": "Write a Python function that sorts a list."}
    ]
  }' | jq .
```

this yields the following response:

```json
{
  "id": "chatcmpl-f6890968-26a2-4c39-8451-b0b043ae135b",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "I can only help with shoes, footwear, sizing, orders, and returns.",
        "role": "assistant"
      }
    }
  ],
  "created": 1794837335,
  "model": "decision-model",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "decision"
  }
}
```