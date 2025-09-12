## Authenticated orchestrator

- Get the route: 
```
FMS_ORCHESTRATOR_URL="https://$(oc get routes guardrails-orchestrator -o jsonpath='{.spec.host}')"
```

- Send a request: 

```
curl -v \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "detectors": {
      "ibm-hap-38m-detector": {}
    },
    "content": "You dotard I hate this stuff!"
  }' \
  "$FMS_ORCHESTRATOR_URL/api/v2/text/detection/content" | jq
```

This should return:

```
{
  "detections": [
    {
      "start": 0,
      "end": 29,
      "text": "You dotard I hate this stuff!",
      "detection": "single_label_classification",
      "detection_type": "LABEL_1",
      "detector_id": "ibm-hap-38m-detector",
      "score": 0.8637843728065491
    }
  ]
}
```


