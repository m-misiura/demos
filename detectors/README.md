## Deploy detector

```
oc apply -f detector_storage.yaml
```

If oauth:

```
oc apply -f hap_oauth.yaml
```

otherwise:

```
oc apply -f hap_no_oauth.yaml
```

## Sample requests -- authenticated

Get the route: 

```
HAP_ROUTE=$(oc get routes hap-detector-route -o jsonpath='{.spec.host}')
```

### Health

```
curl -v -H "Authorization: Bearer $(oc whoami -t)" https://$HAP_ROUTE/health | jq
```

this should return:

`"ok"`

### Trigger some detections and no detections

```
curl -v -X POST \
  "https://$HAP_ROUTE/api/v1/text/contents" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H 'accept: application/json' \
  -H 'detector-id: hap' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["You dotard, I really hate this stuff", "I simply love this stuff"],
    "detector_params": {}
  }' | jq
```

this should return:

```
[
  [
    {
      "start": 0,
      "end": 36,
      "text": "You dotard, I really hate this stuff",
      "detection": "single_label_classification",
      "detection_type": "LABEL_1",
      "score": 0.9634237885475159,
      "evidences": [],
      "metadata": {}
    }
  ],
  []
]
```

## Sample requests -- un-authenticated

Get the route: 

```
HAP_ROUTE=$(oc get routes hap-detector-route -o jsonpath='{.spec.host}')
```

### Health

```
curl -v http://$HAP_ROUTE/health | jq
```

this should return:

`"ok"`

### Trigger some detections and no detections

```
curl -v -X POST \
  "http://$HAP_ROUTE/api/v1/text/contents" \
  -H 'accept: application/json' \
  -H 'detector-id: hap' \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": ["You dotard, I really hate this stuff", "I simply love this stuff"],
    "detector_params": {}
  }' | jq
```

this should return:

```
[
  [
    {
      "start": 0,
      "end": 36,
      "text": "You dotard, I really hate this stuff",
      "detection": "single_label_classification",
      "detection_type": "LABEL_1",
      "score": 0.9634237885475159,
      "evidences": [],
      "metadata": {}
    }
  ],
  []
]
```