## Deployment

Set environment variables with your LLM credentials:
```bash
export LLM_API_BASE="https://your-llm-endpoint.com/v1"
export LLM_MODEL_NAME="your-model-name"
export LLM_API_KEY="your-api-key"
```

Deploy with envsubst:
```bash
envsubst < nemo-config.yaml | oc apply -f -
oc apply -f nemo-deployment.yaml
```

## Testing

Get the route URL:
```bash
NEMO_ROUTE=$(oc get route nemo-lemonade -o jsonpath='{.spec.host}')
echo "NeMo Guardrails URL: http://$NEMO_ROUTE"
```

### Test 1: Basic Lemon Question (Should Work)

```bash
curl -X POST "http://$NEMO_ROUTE/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$LLM_MODEL_NAME"'",
    "messages": [{"role":"user","content":"What are the health benefits of lemons?"}]
  }' | jq
```

should return something along the lines of:

```json
{
  "id": "chatcmpl-9c4856cd-7927-43da-976b-038f94cd109d",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "Lemons are rich in vitamin C, which is essential for a healthy immune system. They also contain antioxidants such as flavonoids, which can help fight inflammation and protect against certain diseases. Moreover, the citric acid in lemons can aid in digestion and promote a healthy stomach. Lemons have a diuretic effect, which can help in reducing bloating by promoting water elimination. They are also known to improve skin health due to their ability to flush out toxins from the body. Additionally, some studies suggest that the flavonoids in lemons may have potential benefits for heart health by reducing blood pressure. Lemon peel contains limonene, which has been studied for its potential anti-cancer properties. Overall, incorporating lemons into your diet can contribute to overall well-being by supporting various bodily functions.",
        "role": "assistant"
      }
    }
  ],
  "created": 1772209331,
  "model": "microsoft/phi-4",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "lemonade-stand"
  }
}
```

### Test 2: Off-Topic Question (Should Refuse)

```bash
curl -X POST "http://$NEMO_ROUTE/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$LLM_MODEL_NAME"'",
    "messages": [{"role":"user","content":"Tell me about oranges"}]
  }' | jq
```

should return something along the lines of:

```json
{
  "id": "chatcmpl-5cbbc4d7-1b3d-4b40-8fec-043fc5d8c168",
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "I'm here to provide information exclusively about lemons. If you have any questions related to lemons, such as their cultivation, varieties, storage, or uses, feel free to ask!",
        "role": "assistant"
      }
    }
  ],
  "created": 1772209366,
  "model": "microsoft/phi-4",
  "object": "chat.completion",
  "guardrails": {
    "config_id": "lemonade-stand"
  }
}
```

### Test 3: Streaming Response

```bash
curl -X POST "http://$NEMO_ROUTE/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$LLM_MODEL_NAME"'",
    "messages": [{"role":"user","content":"Give me a recipe for lemonade"}],
    "stream": true
  }' 
```

should return something along the lines of 

```json
data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "Certa"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "i"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "nly! "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "He"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "re"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "'s a b"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "asic"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " wa"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209450, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "y to e"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "nj"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "oy a refres"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "hing l"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "emon-b"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ased d"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "rin"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "k"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": ":"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "\n\n"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "1. Squ"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "eeze f"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "res"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "h le"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "mon"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "s to ext"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ract"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " the j"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ui"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "c"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "e"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": ".\n2"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": ". "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "In a pit"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "c"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209451, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "her, com"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "bine"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " the l"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "emon j"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "uice "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "with w"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ater"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " and s"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "u"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "gar, adjus"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "tin"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "g to t"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "aste"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " for sweet"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ne"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "s"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "s"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": ".\n3. "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "Stir u"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ntil"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " the s"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ugar "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "disso"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "lv"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "e"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209452, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "s"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": ".\n4."}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " Add"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " ice"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " and "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "gar"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "nish "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "with l"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "emon sl"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ice"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "s or h"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "erbs "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "like "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "mint"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " for e"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "xtra fl"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "av"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "o"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "r"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": ".\n5. S"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "erve chi"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "lled"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " and e"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "njo"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "y!\n\n"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209453, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "Feel "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "fre"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "e to ad"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "just"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " the ra"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "tio"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "s or"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " add ingredi"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ent"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "s to "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "your prefer"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "enc"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "e to custo"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "mize "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "your d"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "r"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ink"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": ". If"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " yo"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "u're intere"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ste"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "d in diffe"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "rent prepara"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "tion met"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "hod"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209454, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "s or variat"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "i"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ons, t"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "here"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " are "}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "many crea"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "tive rec"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ipes"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " you"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": " can exp"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "l"}, "index": 0, "finish_reason": null}]}

data: {"id": "chatcmpl-f7dea43b-04a9-45b8-9e3f-39396f82d931", "object": "chat.completion.chunk", "created": 1772209455, "model": "microsoft/phi-4", "choices": [{"delta": {"content": "ore."}, "index": 0, "finish_reason": null}]}

data: [DONE]
```

