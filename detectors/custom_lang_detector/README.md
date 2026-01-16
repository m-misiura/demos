1. Run `oc get configmap trustyai-service-operator-config -n redhat-ods-applications -o jsonpath='{.data}' | jq .` to see the current images

2. Replace `guardrails-built-in-detector-image` with an image that has the required python libraries for the custom detectors, e.g. `quay.io/rh-ee-mmisiura/guardrails-built-in-detector-image:lingua` for an image that has [lingua](https://github.com/pemistahl/lingua-py):

```bash
 oc patch configmap trustyai-service-operator-config -n redhat-ods-applications --type='json' -p='[{"op": "replace", "path": "/data/guardrails-built-in-detector-image", "value": "quay.io/rh-ee-mmisiura/guardrails-built-in-detector-image:lingua"}]'
```

3. Create `configmap`

```bash
oc create configmap custom-detectors --from-file=custom_detectors.py
```

4. Apply `lingua_detector.yaml` to create the custom detector

```bash
oc apply -f lingua_detector.yaml 
```

5. Get route to access the detector service

```bash
ROUTE=$(oc get route custom-guardrails-built-in -o jsonpath='{.spec.host}')
```

6. Test the detector with english 

```bash
curl -X POST https://$ROUTE/api/v1/text/contents \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "contents": ["Hello, this is a test message in English."],
    "detector_params": {
      "custom": {
        "english_only": {
            "confidence_threshold": 0.3}
      }
    }
  }' | jq .
```

which should return:

```json
[
  []
]
```

7. Test the detector with non-english 

```bash
curl -X POST https://$ROUTE/api/v1/text/contents \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "contents": ["Czesc, to jest test po Polsku"],
    "detector_params": {
      "custom": {
        "english_only": {
            "confidence_threshold": 0.3}
      }
    }
  }' | jq .
```
