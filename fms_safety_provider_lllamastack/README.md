## Deploy lls distro

Export the following variables:

```
export FMS_ORCHESTRATOR_URL="https://$(oc get routes guardrails-orchestrator  -o jsonpath='{.spec.host}')"
export VLLM_URL="<INSERT_URL_HERE/v1"
export VLLM_API_TOKEN="<INSERT_TOKEN_HERE>"
export INFERENCE_MODEL="<INSERT_MODEL_HERE>"
```

Then run:

```
envsubst < lls_distro.yaml | oc apply -f -
```

## Get route of the service

```
oc expose service lls-fms-service --name=lls-route
LLS_ROUTE=$(oc get route lls-route -o jsonpath='{.spec.host}')

```

## Register shields

```
TOKEN=$(oc whoami -t)
```

```
curl -X 'POST' \
"http://$LLS_ROUTE/v1/shields" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-d '{
  "shield_id": "secure_shield",
  "provider_shield_id": "secure_shield",
  "provider_id": "trustyai_fms",
  "params": {
    "type": "content",
    "confidence_threshold": 0.5,
    "message_types": ["system", "user"],
    "auth_token": "'"$TOKEN"'",
    "verify_ssl": true,
    "detectors": {
      "ibm-hap-38m-detector": {
        "detector_params": {}
      },
      "built-in-detector": {
        "detector_params": {
          "regex": ["email", "ssn", "credit-card", "^hello$"]
        }
      }
    }
  }
}'
```

## Sample requests -- run-shield

- trigger the regex detector 

```bash
curl -X POST "http://$LLS_ROUTE/v1/safety/run-shield" \
-H "Content-Type: application/json" \
-d '{
  "shield_id": "secure_shield",
  "messages": [
    {
      "content": "My email is test@example.com",
      "role": "system"
    }
  ]
}' | jq '.'
```

this should return:

```
{
  "violation": {
    "violation_level": "error",
    "user_message": "Content violation detected by shield secure_shield (confidence: 1.00, 1/1 processed messages violated)",
    "metadata": {
      "status": "violation",
      "shield_id": "secure_shield",
      "confidence_threshold": 0.5,
      "summary": {
        "total_messages": 1,
        "processed_messages": 1,
        "skipped_messages": 0,
        "messages_with_violations": 1,
        "messages_passed": 0,
        "message_fail_rate": 1.0,
        "message_pass_rate": 0.0,
        "total_detections": 1,
        "detector_breakdown": {
          "active_detectors": 2,
          "total_checks_performed": 2,
          "total_violations_found": 1,
          "violations_per_message": 1.0
        }
      },
      "results": [
        {
          "message_index": 0,
          "text": "My email is test@example.com",
          "status": "violation",
          "score": 1.0,
          "detection_type": "pii",
          "individual_detector_results": [
            {
              "detector_id": "ibm-hap-38m-detector",
              "status": "pass",
              "score": null,
              "detection_type": null
            },
            {
              "detector_id": "built-in-detector",
              "status": "violation",
              "score": 1.0,
              "detection_type": "pii"
            }
          ]
        }
      ]
    }
  }
}
```

- trigger the hap detector

```bash
curl -X POST "http://$LLS_ROUTE/v1/safety/run-shield" \
-H "Content-Type: application/json" \
-d '{
  "shield_id": "secure_shield",
  "messages": [
    {
      "content": "You dotard, I really hate this",
      "role": "system"
    }
  ]
}' | jq '.'
```

this should return

```
{
  "violation": {
    "violation_level": "error",
    "user_message": "Content violation detected by shield secure_shield (confidence: 0.98, 1/1 processed messages violated)",
    "metadata": {
      "status": "violation",
      "shield_id": "secure_shield",
      "confidence_threshold": 0.5,
      "summary": {
        "total_messages": 1,
        "processed_messages": 1,
        "skipped_messages": 0,
        "messages_with_violations": 1,
        "messages_passed": 0,
        "message_fail_rate": 1.0,
        "message_pass_rate": 0.0,
        "total_detections": 1,
        "detector_breakdown": {
          "active_detectors": 2,
          "total_checks_performed": 2,
          "total_violations_found": 1,
          "violations_per_message": 1.0
        }
      },
      "results": [
        {
          "message_index": 0,
          "text": "You dotard, I really hate this",
          "status": "violation",
          "score": 0.9750116467475892,
          "detection_type": "LABEL_1",
          "individual_detector_results": [
            {
              "detector_id": "ibm-hap-38m-detector",
              "status": "violation",
              "score": 0.9750116467475892,
              "detection_type": "LABEL_1"
            },
            {
              "detector_id": "built-in-detector",
              "status": "pass",
              "score": null,
              "detection_type": null
            }
          ]
        }
      ]
    }
  }
}
```

## Sample requests -- moderations

```
curl -X POST http://$LLS_ROUTE/v1/openai/v1/moderations \
  -H "Content-Type: application/json" \
  -d '{
    "input": ["You dotard, I really hate this", "My email is test@email.com", "This is a test message"],
    "model": "secure_shield"
  }' | jq
```

which should return:

```
{
  "id": "673d6e0f-11ba-4760-a826-c6b87f21ed9c",
  "model": "secure_shield",
  "results": [
    {
      "flagged": true,
      "categories": {
        "LABEL_1": true
      },
      "category_applied_input_types": {
        "LABEL_1": [
          "text"
        ]
      },
      "category_scores": {
        "LABEL_1": 0.9750116467475892
      },
      "user_message": "You dotard, I really hate this",
      "metadata": {
        "message_index": 0,
        "text": "You dotard, I really hate this",
        "status": "violation",
        "score": 0.9750116467475892,
        "detection_type": "LABEL_1",
        "individual_detector_results": [
          {
            "detector_id": "ibm-hap-38m-detector",
            "status": "violation",
            "score": 0.9750116467475892,
            "detection_type": "LABEL_1"
          },
          {
            "detector_id": "built-in-detector",
            "status": "pass",
            "score": null,
            "detection_type": null
          }
        ]
      }
    },
    {
      "flagged": true,
      "categories": {
        "pii": true
      },
      "category_applied_input_types": {
        "pii": [
          "text"
        ]
      },
      "category_scores": {
        "pii": 1.0
      },
      "user_message": "My email is test@email.com",
      "metadata": {
        "message_index": 1,
        "text": "My email is test@email.com",
        "status": "violation",
        "score": 1.0,
        "detection_type": "pii",
        "individual_detector_results": [
          {
            "detector_id": "ibm-hap-38m-detector",
            "status": "pass",
            "score": null,
            "detection_type": null
          },
          {
            "detector_id": "built-in-detector",
            "status": "violation",
            "score": 1.0,
            "detection_type": "pii"
          }
        ]
      }
    },
    {
      "flagged": false,
      "categories": {},
      "category_applied_input_types": {},
      "category_scores": {},
      "user_message": "This is a test message",
      "metadata": {
        "message_index": 2,
        "text": "This is a test message",
        "status": "pass",
        "score": null,
        "detection_type": null,
        "individual_detector_results": [
          {
            "detector_id": "ibm-hap-38m-detector",
            "status": "pass",
            "score": null,
            "detection_type": null
          },
          {
            "detector_id": "built-in-detector",
            "status": "pass",
            "score": null,
            "detection_type": null
          }
        ]
      }
    }
  ]
}
```

Note also that sometimes, you need to mount the appropriate certs to the llama stack distribution ; for an example of how to do this, see e.g. [this demo](https://github.com/m-misiura/llama-stack-k8s/tree/tls-testing)