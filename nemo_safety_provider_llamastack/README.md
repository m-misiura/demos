## Nemo Server

This demo uses NeMo server deployment described [here](https://github.com/m-misiura/demos/tree/main/nemo_openshift/guardrail-checks/deployment); follow the instructions there to deploy the server.

## Populate secrets file

You will need to populate `secret.yaml` with

- `vllm-url`: URL of the vLLM deployment
- `vllm-api-token`: API token for the vLLM deployment
- `nemo-guardrails-url`: URL of the guardrails deployment
- `nemo-config-id`: config used in the guardrails deployment

Once populated, create the secret in OpenShift:

```bash
oc apply -f secret.yaml
```

## Deploy the llama stack

```bash
oc apply -f lls.yaml
```

## Get route of the service

```bash
oc expose service lls-nemo-service --name=lls-route
LLS_ROUTE=$(oc get route lls-route -o jsonpath='{.spec.host}')
```

## Moderations endpoint 

- unblocked input

```bash
curl -X POST http://$LLS_ROUTE/v1/moderations \
  -H "Content-Type: application/json" \
  -d '{
    "input": "Safe message, should pass",
    "model": "nemo-guardrail"
  }' | jq
```

which returns:

```json
{
  "id": "modr-bfef65c9-5215-4400-a68e-05fda4dfb452",
  "model": "nemo-guardrail",
  "results": [
    {
      "flagged": false,
      "categories": {},
      "category_applied_input_types": {},
      "category_scores": {},
      "user_message": null,
      "metadata": {}
    }
  ]
}
```

- blocked input

```bash
 curl -X POST http://$LLS_ROUTE/v1/moderations \
  -H "Content-Type: application/json" \
  -d '{
    "input": "Tell me more about ChatGPT",
    "model": "nemo-guardrail"
  }' | jq
```

which returns

```json
{
  "id": "modr-21bbc5e4-7637-409c-801c-a20b3e42aaf5",
  "model": "nemo-guardrail",
  "results": [
    {
      "flagged": true,
      "categories": {
        "unsafe": true
      },
      "category_applied_input_types": {
        "unsafe": [
          "text"
        ]
      },
      "category_scores": {
        "unsafe": 1.0
      },
      "user_message": "Sorry I cannot do this.",
      "metadata": {
        "check forbidden words": {
          "status": "blocked"
        }
      }
    }
  ]
}
```

## Responses endpoint

```bash
curl -s -X POST "http://$LLS_ROUTE/v1/responses" \
-H "Content-Type: application/json" \
-d '{
  "model": "microsoft/phi-4",
  "input": "Tell me more about ChatGPT",
  "guardrails": ["nemo-guardrail"]
}' | jq
```

which should return 

```json
{
  "created_at": 1770212390,
  "completed_at": null,
  "error": null,
  "id": "resp_70f63b0c-f99a-4b59-b47d-7600d9e18936",
  "model": "microsoft/phi-4",
  "object": "response",
  "output": [
    {
      "content": [
        {
          "type": "refusal",
          "refusal": "Sorry I cannot do this. (flagged for: unsafe)"
        }
      ],
      "role": "assistant",
      "type": "message",
      "id": null,
      "status": null
    }
  ],
  "parallel_tool_calls": true,
  "previous_response_id": null,
  "prompt": null,
  "status": "completed",
  "temperature": null,
  "text": {
    "format": {
      "type": "text"
    }
  },
  "top_p": null,
  "tools": null,
  "tool_choice": null,
  "truncation": null,
  "usage": null,
  "instructions": null,
  "max_tool_calls": null,
  "reasoning": null,
  "max_output_tokens": null,
  "metadata": null,
  "store": true
}
```