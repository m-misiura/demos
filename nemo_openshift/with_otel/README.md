## Setup OpenTelemtry with Tempo

```bash
oc apply -f tempo
```

## Deploy NeMo via CRD

- set your environment variables:

```bash
export OPENAI_API_KEY=<your-openai-api-key>
export MAIN_MODEL_BASE_URL=<your-model-base-url>
export MODEL_NAME=<your-model-name>
export MAIN_MODEL_ENGINE=<your-engine-name>
export TEMPO_ENDPOINT=<your-tempo-endpoint>
```

- deploy the secret

```bash
envsubst < secret.yaml | oc apply -f -
```

- deploy the ConfigMap (explicit variable list to preserve Colang syntax):

```bash
envsubst '${MAIN_MODEL_ENGINE} ${MAIN_MODEL_BASE_URL} ${MODEL_NAME} ${OPENAI_API_KEY} ${TEMPO_ENDPOINT}' < configmap.yaml | oc apply -f -
```

note that if you want to enable content tracing, you should use the `configmap-content.yaml` instead, which has additional NeMo tracing config

- deploy the NemoGuardrails CR:

```bash
oc apply -f nemo.yaml
```


- get the route:

```bash
NEMO_ROUTE=$(oc get route nemo -o jsonpath='{.spec.host}')
```

## Test Cases

### Test 0: Check Models Endpoint

```bash
curl -H "Authorization: Bearer $(oc whoami -t)" \
  "https://$NEMO_ROUTE/v1/models" | jq
```

this should return

```json
{
  "data": [
    {
      "id": "microsoft-phi-4",
      "created": 1677610602,
      "object": "model",
      "owned_by": "openai"
    }
  ]
}
```

### Test 1: PII Detection - Email Address (Should Block)

```bash
curl -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL_NAME"'",
    "messages": [{"role":"user","content":"My email is john.doe@example.com, can you help me?"}]
  }' \
  "https://$NEMO_ROUTE/v1/chat/completions" | jq
```

this should return

```json
{
  "id": "chatcmpl-1ce8b366-700e-4f0f-864c-0935710065db",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "I don't know the answer to that.",
        "role": "assistant"
      }
    }
  ],
  "created": 1775642623,
  "model": "microsoft-phi-4",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "pii"
  }
}
```

### Test 2: PII Detection - SSN (Should Block)

```bash
curl -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL_NAME"'",
    "messages": [{"role":"user","content":"My SSN is 856-45-6789"}]
  }' \
  "https://$NEMO_ROUTE/v1/chat/completions" | jq
```

ths should return

```json
{
  "id": "chatcmpl-f73530b9-456e-41c7-a2e1-6aae46fad75c",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "I don't know the answer to that.",
        "role": "assistant"
      }
    }
  ],
  "created": 1775642692,
  "model": "microsoft-phi-4",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "pii"
  }
}
```

### Test 3: PII Detection - Credit Card (Should Block)

```bash
curl -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL_NAME"'",
    "messages": [{"role":"user","content":"Please charge my credit card 4532015112830366"}]
  }' \
  "https://$NEMO_ROUTE/v1/chat/completions" | jq
```

this should return

```json
{
  "id": "chatcmpl-b76ab5c2-51e6-42ce-8808-e29db09f756c",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "I don't know the answer to that.",
        "role": "assistant"
      }
    }
  ],
  "created": 1775642705,
  "model": "microsoft-phi-4",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "pii"
  }
}
```

### Test 4: PII Detection - Phone Number (Should Block)

```bash
curl -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL_NAME"'",
    "messages": [{"role":"user","content":"Call me at 555-123-4567 for details"}]
  }' \
  "https://$NEMO_ROUTE/v1/chat/completions" | jq
```

this should return

```json
{
  "id": "chatcmpl-aefae350-8ebe-4aa2-a55e-956829c7a492",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "I don't know the answer to that.",
        "role": "assistant"
      }
    }
  ],
  "created": 1775642717,
  "model": "microsoft-phi-4",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "pii"
  }
}
```

### Test 5: Normal Request (Should Pass)

```bash
curl -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL_NAME"'",
    "messages": [{"role":"user","content":"What are best practices for data security? Answer in 3 sentences"}]
  }' \
  "https://$NEMO_ROUTE/v1/chat/completions" | jq
```

this should return 

```json
{
  "id": "chatcmpl-60bd53a4-84aa-40ad-8134-ae51b1c4757c",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "Implementing strong, unique passwords and enabling two-factor authentication are foundational practices for protecting data. Regularly updating software and systems helps patch vulnerabilities that could be exploited by malicious actors. Additionally, conducting routine security audits and employee training ensures that your organization is aware of potential threats and prepared to respond appropriately.",
        "role": "assistant"
      }
    }
  ],
  "created": 1775642663,
  "model": "microsoft-phi-4",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "pii"
  }
}
```

## Querying Tempo Traces

### Via Jaeger UI

- The TempoStack deploys a Jaeger Query frontend with a route (it will be removed in future releases). Get the URL:

```bash
JAEGER_ROUTE=$(oc get route tempo-sample-query-frontend -o jsonpath='{.spec.host}')
echo "https://$JAEGER_ROUTE"
```

Open the URL in your browser, select `nemo-guardrails` from the Service dropdown, and click **Find Traces**.

### Via CLI (Tempo API)

- Port-forward the query frontend:

```bash
oc port-forward svc/tempo-sample-query-frontend 3200:3200
```

- Search for traces by service name:

```bash
curl -s "http://localhost:3200/api/search?tags=service.name%3Dnemo-guardrails&limit=5" | jq
```

would return

```json
{
  "traces": [
    {
      "traceID": "c71a7ba2ea10bb89d8c3fc95987a9bd",
      "rootServiceName": "nemo-guardrails",
      "rootTraceName": "POST /v1/chat/completions",
      "startTimeUnixNano": "1775642639295777273",
      "durationMs": 53
    },
    {
      "traceID": "404c4e4cda13d78924349e481c1413e1",
      "rootServiceName": "nemo-guardrails",
      "rootTraceName": "POST /v1/chat/completions",
      "startTimeUnixNano": "1775642620905164061",
      "durationMs": 2858
    },
    {
      "traceID": "675db355c0a0fa09267c3568386d5c9a",
      "rootServiceName": "nemo-guardrails",
      "rootTraceName": "GET /",
      "startTimeUnixNano": "1775642619880765187",
      "durationMs": 1
    },
    {
      "traceID": "cd48fe04179f973f93d40dc177e7da3d",
      "rootServiceName": "nemo-guardrails",
      "rootTraceName": "GET /v1/models",
      "startTimeUnixNano": "1775642600925816453",
      "durationMs": 257
    },
    {
      "traceID": "16f5dc56004d10214fb121f4e12731f9",
      "rootServiceName": "nemo-guardrails",
      "rootTraceName": "GET /",
      "startTimeUnixNano": "1775642599880276807",
      "durationMs": 1
    }
  ],
  "metrics": {
    "inspectedTraces": 6,
    "inspectedBytes": "81516",
    "completedJobs": 1,
    "totalJobs": 3
  }
}
```

- Get a specific trace by ID:

```bash
curl -s "http://localhost:3200/api/traces/<trace-id>" | jq
```

e.g.

```bash
curl -s "http://localhost:3200/api/traces/404c4e4cda13d78924349e481c1413e1" | jq
```

would return

```json
{
  "batches": [
    {
      "resource": {
        "attributes": [
          {
            "key": "telemetry.auto.version",
            "value": {
              "stringValue": "0.59b0"
            }
          },
          {
            "key": "telemetry.sdk.language",
            "value": {
              "stringValue": "python"
            }
          },
          {
            "key": "telemetry.sdk.name",
            "value": {
              "stringValue": "opentelemetry"
            }
          },
          {
            "key": "telemetry.sdk.version",
            "value": {
              "stringValue": "1.38.0"
            }
          },
          {
            "key": "service.name",
            "value": {
              "stringValue": "nemo-guardrails"
            }
          }
        ]
      },
      "scopeSpans": [
        {
          "scope": {
            "name": "opentelemetry.instrumentation.fastapi",
            "version": "0.59b0"
          },
          "spans": [
            {
              "traceId": "QExOTNoT14kkNJ5IHBQT4Q==",
              "spanId": "ldzZJLv8RNY=",
              "parentSpanId": "YdBcEaRQ6a0=",
              "name": "POST /v1/chat/completions http receive",
              "kind": "SPAN_KIND_INTERNAL",
              "startTimeUnixNano": "1775642620905322382",
              "endTimeUnixNano": "1775642620905344507",
              "attributes": [
                {
                  "key": "asgi.event.type",
                  "value": {
                    "stringValue": "http.request"
                  }
                }
              ],
              "status": {}
            },
            {
              "traceId": "QExOTNoT14kkNJ5IHBQT4Q==",
              "spanId": "WWrBUDtBi04=",
              "parentSpanId": "YdBcEaRQ6a0=",
              "name": "POST /v1/chat/completions http send",
              "kind": "SPAN_KIND_INTERNAL",
              "startTimeUnixNano": "1775642623762749615",
              "endTimeUnixNano": "1775642623762793996",
              "attributes": [
                {
                  "key": "asgi.event.type",
                  "value": {
                    "stringValue": "http.response.start"
                  }
                },
                {
                  "key": "http.status_code",
                  "value": {
                    "intValue": "200"
                  }
                }
              ],
              "status": {}
            },
            {
              "traceId": "QExOTNoT14kkNJ5IHBQT4Q==",
              "spanId": "J7y4WmHl02s=",
              "parentSpanId": "YdBcEaRQ6a0=",
              "name": "POST /v1/chat/completions http send",
              "kind": "SPAN_KIND_INTERNAL",
              "startTimeUnixNano": "1775642623763139686",
              "endTimeUnixNano": "1775642623763158008",
              "attributes": [
                {
                  "key": "asgi.event.type",
                  "value": {
                    "stringValue": "http.response.body"
                  }
                }
              ],
              "status": {}
            },
            {
              "traceId": "QExOTNoT14kkNJ5IHBQT4Q==",
              "spanId": "YdBcEaRQ6a0=",
              "name": "POST /v1/chat/completions",
              "kind": "SPAN_KIND_SERVER",
              "startTimeUnixNano": "1775642620905164061",
              "endTimeUnixNano": "1775642623763267470",
              "attributes": [
                {
                  "key": "http.scheme",
                  "value": {
                    "stringValue": "https"
                  }
                },
                {
                  "key": "http.host",
                  "value": {
                    "stringValue": "127.0.0.1:8000"
                  }
                },
                {
                  "key": "net.host.port",
                  "value": {
                    "intValue": "8000"
                  }
                },
                {
                  "key": "http.flavor",
                  "value": {
                    "stringValue": "1.1"
                  }
                },
                {
                  "key": "http.target",
                  "value": {
                    "stringValue": "/v1/chat/completions"
                  }
                },
                {
                  "key": "http.server_name",
                  "value": {
                    "stringValue": "nemo-remove-jailbreak.apps.rosa.trustyai-mac.v5di.p3.openshiftapps.com"
                  }
                },
                {
                  "key": "http.user_agent",
                  "value": {
                    "stringValue": "curl/8.7.1"
                  }
                },
                {
                  "key": "net.peer.ip",
                  "value": {
                    "stringValue": "10.129.22.12"
                  }
                },
                {
                  "key": "http.route",
                  "value": {
                    "stringValue": "/v1/chat/completions"
                  }
                },
                {
                  "key": "http.method",
                  "value": {
                    "stringValue": "POST"
                  }
                },
                {
                  "key": "http.url",
                  "value": {
                    "stringValue": "https://nemo-remove-jailbreak.apps.rosa.trustyai-mac.v5di.p3.openshiftapps.com/v1/chat/completions"
                  }
                },
                {
                  "key": "http.status_code",
                  "value": {
                    "intValue": "200"
                  }
                }
              ],
              "status": {}
            }
          ]
        }
      ]
    }
  ]
}
```

