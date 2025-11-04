## Get the route

```bash
EMBEDDING_ROUTE=$(oc get routes embedding-detector-route -o jsonpath='{.spec.host}')
```

## Make a request to the embedding model

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

## Make requests to the topic detector that uses the embedding model

```bash
TOPIC_DETECTOR_ROUTE=$(oc get routes topic-detector -o jsonpath='{.spec.host}')
```

```bash
curl -v -X POST \
  "https://${TOPIC_DETECTOR_ROUTE}/api/v1/text/contents" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [
      "What is the weather?",
      "Tell me how to make a tasty cake?"
    ],
    "detector_params": {
      "custom": ["check_topic"]
    }
  }' | jq
```

which should return something like

```
[
  [
    {
      "start": 0,
      "end": 20,
      "text": "What is the weather?",
      "detection": "off_topic",
      "detection_type": "off_topic",
      "score": 0.24855115794544336,
      "evidences": null,
      "metadata": {}
    }
  ],
  []
]
```