## Sample requests


```
export FMS_ORCHESTRATOR_URL="https://$(oc get routes guardrails-orchestrator  -o jsonpath='{.spec.host}')"
```

```
curl \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "detectors": {
      "ibm-hap-38m-detector": {}
    },
    "content": "lllllllllllll kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk ooooooooooooooooooooooooooooo lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllliiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii You dotard I hate this stuff! This is a test."
  }' \
  "$FMS_ORCHESTRATOR_URL/api/v2/text/detection/content" | jq
```


```
curl \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "detectors": {
      "ibm-hap-38m-detector": {}
    },
    "content": "This is the first paragraph with multiple sentences. It contains several thoughts and ideas that belong together.\n\nThis is the second paragraph with different content. It discusses a separate topic from the first paragraph.\n\nThis is the third paragraph with concluding thoughts. It wraps up the discussion from the previous paragraphs."
  }' \
  "$FMS_ORCHESTRATOR_URL/api/v2/text/detection/content" | jq
```

```
curl \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "detectors": {
      "ibm-hap-38m-detector": {}
    },
    "content": "You dotard I hate this stuff! This is a test. "
  }' \
  "$FMS_ORCHESTRATOR_URL/api/v2/text/detection/content" | jq
```

```
curl \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "detectors": {
      "ibm-hap-38m-detector": {}
    },
    "content": "# Introduction\nThis is a long document that will be split intelligently by the recursive character text splitter.\n\n## Section 1\nThis section contains multiple sentences. It has various punctuation marks! And it demonstrates how the recursive chunker works? It tries different separators in hierarchical order.\n\n## Section 2\nThis section has more content that continues the discussion. The recursive chunker will try to split on double newlines first, then single newlines, then sentences, then words if needed to stay under the chunk size limit of xxx characters."
  }' \
  "$FMS_ORCHESTRATOR_URL/api/v2/text/detection/content" | jq
```