# Token Classification Detector - Test Curls

after you deploy with: 

```bash 
oc apply -f deploy.yaml
```

run

```bash
export ROUTE=$(oc get route detector-ner-route -o jsonpath='{.spec.host}')
```

### Basic NER detection

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["John Smith works at Google in London"],
    "detector_params": {}
  }' | jq
```

should yield

```json
[
  [
    {
      "start": 0,
      "end": 4,
      "text": "John",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.9985226988792419,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 5,
      "end": 10,
      "text": "Smith",
      "detection": "detection",
      "detection_type": "I-PER",
      "score": 0.9983487129211426,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 20,
      "end": 26,
      "text": "Google",
      "detection": "detection",
      "detection_type": "B-ORG",
      "score": 0.9967825412750244,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 30,
      "end": 36,
      "text": "London",
      "detection": "detection",
      "detection_type": "B-LOC",
      "score": 0.965920627117157,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Multiple contents (one with entities, one clean)

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": [
      "Angela Merkel visited the European Parliament in Strasbourg",
      "The weather is nice today"
    ],
    "detector_params": {}
  }' | jq
```

should yield

```json
[
  [
    {
      "start": 0,
      "end": 6,
      "text": "Angela",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.9991115927696228,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 7,
      "end": 13,
      "text": "Merkel",
      "detection": "detection",
      "detection_type": "I-PER",
      "score": 0.9992121060689291,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 26,
      "end": 34,
      "text": "European",
      "detection": "detection",
      "detection_type": "B-ORG",
      "score": 0.8845784664154053,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 35,
      "end": 45,
      "text": "Parliament",
      "detection": "detection",
      "detection_type": "I-ORG",
      "score": 0.944580614566803,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 49,
      "end": 59,
      "text": "Strasbourg",
      "detection": "detection",
      "detection_type": "B-LOC",
      "score": 0.9906805157661438,
      "evidences": [],
      "metadata": {}
    }
  ],
  []
]
```

### Custom threshold

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["Send the report to alice"],
    "detector_params": {"threshold": 0.0001}
  }' | jq
```
should yield

```json
[
  [
    {
      "start": 19,
      "end": 24,
      "text": "alice",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.00023383545340038836,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Filtering with safe_labels (only detect PER, suppress everything else)

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["Barack Obama gave a speech at the United Nations in New York"],
    "detector_params": {
      "safe_labels": ["B-LOC", "I-LOC", "B-ORG", "I-ORG", "B-MISC", "I-MISC"]
    }
  }' | jq
```
should yield

```json
[
  [
    {
      "start": 0,
      "end": 6,
      "text": "Barack",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.89572674036026,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 7,
      "end": 12,
      "text": "Obama",
      "detection": "detection",
      "detection_type": "I-PER",
      "score": 0.9420488476753235,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Per-label thresholds

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["John Smith works at Google in London"],
    "detector_params": {
      "label_thresholds": {
        "B-ORG": 0.9999,
        "I-ORG": 0.9999,
        "B-LOC": 0.3
      }
    }
  }' | jq
```

should yield

```
[
    {
      "start": 0,
      "end": 4,
      "text": "John",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.9985226988792419,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 5,
      "end": 10,
      "text": "Smith",
      "detection": "detection",
      "detection_type": "I-PER",
      "score": 0.9983487129211426,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 30,
      "end": 36,
      "text": "London",
      "detection": "detection",
      "detection_type": "B-LOC",
      "score": 0.965920627117157,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Safe labels (suppress specific labels)

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["John Smith works at Google in London"],
    "detector_params": {
      "safe_labels": ["B-PER", "I-PER"]
    }
  }' | jq
```

should yield

```json
[
  [
    {
      "start": 20,
      "end": 26,
      "text": "Google",
      "detection": "detection",
      "detection_type": "B-ORG",
      "score": 0.9967825412750244,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 30,
      "end": 36,
      "text": "London",
      "detection": "detection",
      "detection_type": "B-LOC",
      "score": 0.965920627117157,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Combined: threshold + label_thresholds + safe_labels

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["John Smith works at Google in London"],
    "detector_params": {
      "threshold": 0.8,
      "safe_labels": ["B-MISC", "I-MISC"],
      "label_thresholds": {
        "B-PER": 0.999,
        "I-PER": 0.999
      }
    }
  }' | jq
```

should yield

```json
[
  [
    {
      "start": 20,
      "end": 26,
      "text": "Google",
      "detection": "detection",
      "detection_type": "B-ORG",
      "score": 0.9967825412750244,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 30,
      "end": 36,
      "text": "London",
      "detection": "detection",
      "detection_type": "B-LOC",
      "score": 0.965920627117157,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### max_length override

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["John Smith works at Google in London and Angela Merkel visited the European Union headquarters in Brussels"],
    "detector_params": {"max_length": 16}
  }' | jq
```

should yield

```json
[
  [
    {
      "start": 0,
      "end": 4,
      "text": "John",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.9988898634910583,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 5,
      "end": 10,
      "text": "Smith",
      "detection": "detection",
      "detection_type": "I-PER",
      "score": 0.9985575079917908,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 20,
      "end": 26,
      "text": "Google",
      "detection": "detection",
      "detection_type": "B-ORG",
      "score": 0.9961129426956177,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 30,
      "end": 36,
      "text": "London",
      "detection": "detection",
      "detection_type": "B-LOC",
      "score": 0.9946233034133911,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 41,
      "end": 47,
      "text": "Angela",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.999359667301178,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 48,
      "end": 54,
      "text": "Merkel",
      "detection": "detection",
      "detection_type": "I-PER",
      "score": 0.9991720716158549,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Invalid threshold type (graceful fallback to default)

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["John Smith works at Google in London"],
    "detector_params": {"threshold": "high"}
  }' | jq
```

should yield

```json
[
  [
    {
      "start": 0,
      "end": 4,
      "text": "John",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.9985226988792419,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 5,
      "end": 10,
      "text": "Smith",
      "detection": "detection",
      "detection_type": "I-PER",
      "score": 0.9983487129211426,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 20,
      "end": 26,
      "text": "Google",
      "detection": "detection",
      "detection_type": "B-ORG",
      "score": 0.9967825412750244,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 30,
      "end": 36,
      "text": "London",
      "detection": "detection",
      "detection_type": "B-LOC",
      "score": 0.965920627117157,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Unknown keys in detector_params (ignored)

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["John Smith works at Google in London"],
    "detector_params": {
      "threshold": 0.9,
      "unknown_key": "some_value",
      "another_key": 42
    }
  }' | jq
```

should yield

```json
[
  [
    {
      "start": 0,
      "end": 4,
      "text": "John",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.9985226988792419,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 5,
      "end": 10,
      "text": "Smith",
      "detection": "detection",
      "detection_type": "I-PER",
      "score": 0.9983487129211426,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 20,
      "end": 26,
      "text": "Google",
      "detection": "detection",
      "detection_type": "B-ORG",
      "score": 0.9967825412750244,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 30,
      "end": 36,
      "text": "London",
      "detection": "detection",
      "detection_type": "B-LOC",
      "score": 0.965920627117157,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Threshold of 0.0 (detect everything)

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["The weather is nice today"],
    "detector_params": {"threshold": 0.0}
  }' | jq
```

should yield

```json
[
  [
    {
      "start": 0,
      "end": 3,
      "text": "The",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.000026320209144614637,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 4,
      "end": 14,
      "text": "weather is",
      "detection": "detection",
      "detection_type": "I-ORG",
      "score": 0.000029176537282182835,
      "evidences": [],
      "metadata": {}
    },
    {
      "start": 15,
      "end": 25,
      "text": "nice today",
      "detection": "detection",
      "detection_type": "B-PER",
      "score": 0.000033914735467988066,
      "evidences": [],
      "metadata": {}
    }
  ]
]
```

### Threshold of 1.0 (detect nothing)

```bash
curl -X POST \
  "https://$ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'detector-id: detector-ner' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["John Smith works at Google in London"],
    "detector_params": {"threshold": 1.0}
  }' | jq
```

should yield

```json
[
  []
]
```
