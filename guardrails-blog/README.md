## Prompt injection detector blog post instructions

For the blog post on [evaluating guardrails detectors for prompt injection attacks](https://github.com/trustyai-explainability/trustyai-blog/pull/31), follow the steps below:

1. find candidate models
2. deploy selected models as detectors
3. evaluate deployed detectors

### 0. Assumptions

The following assumptions are made:

- you have a python 3.13.5 virtual environment
- you have `huggingface-cli` and `oc` installed
- you have access to a RHOAI 2.25 cluster with the TrustyAI component enabled 
- you have GPU nodes available in your cluster
- you have access to a [MAAS](https://maas.apps.prod.rhoai.rh-aiservices-bu.com/) model

### 1. Find candidate models

Navigate to the `guardrails-blogs` folder and activate your python virtual environment. Run the following `huggingface-cli` command to check your authentication status:

```bash
hf auth whoami
```

If not logged in, run

```bash
hf auth login
```

and input your Hugging Face token

Next you can download package to discover candidate models:

```bash
pip install git+https://github.com/m-misiura/discover-hf-models.git
```

Run the following command to discover candidate prompt injection models:

```bash
discover-models --use-default-config
```

The default config searches for models with the following criteria:

```json
{
  "keywords": [
    "prompt injection",
    "jailbreak",
    "prompt guard",
    "prompt defense",
    "prompt attack",
    "adversarial prompt",
    "malicious prompt"
  ],
  "licenses": ["mit", "apache-2.0", "apache", "bsd", "gpl", "lgpl", "mpl", "cc-by", "cc0", "unlicense", "other"],
  "pipeline_tags": ["text-classification"],
  "binary_classifier_only": true,
  "output": "results/prompt_injection_models.json",
  "require_license": true,
  "max_workers": 1
}
```

To analyse the results, you can run:

```bash
analyze-models results/prompt_injection_models.json
```

For a search conducted on 29 October 2025, the above command returned the following:

```bash

============================================================
Model Discovery Analysis
============================================================

Total models: 31

License Distribution:
  apache-2.0: 23 (74.2%)
  mit: 7 (22.6%)
  other: 1 (3.2%)

Classification Type:
  Binary classifiers: 31 (100.0%)
  Multiclass classifiers: 0 (0.0%)
  Unknown: 0 (0.0%)

Architecture Distribution:
  DebertaV2ForSequenceClassification: 13
  DistilBertForSequenceClassification: 6
  ModernBertForSequenceClassification: 5
  BertForSequenceClassification: 4
  RobertaForSequenceClassification: 2
  Gemma3TextForSequenceClassification: 1

Pipeline Tag Distribution:
  text-classification: 31 (100.0%)

Models Per Year:
  2023: 3 (9.7%)
  2024: 7 (22.6%)
  2025: 21 (67.7%)

Downloads Statistics:
  Min: 0
  Max: 258,660
  Mean: 11,283
  Median: 36
  Total: 349,781

Likes Statistics:
  Min: 0
  Max: 85
  Mean: 6
  Median: 0

Data Completeness:
  Models with README: 31 (100.0%)
  Models with config.json: 31 (100.0%)


Top 10 Models by Downloads:
--------------------------------------------------------------------------------
 1. protectai/deberta-v3-base-prompt-injection-v2
    Downloads: 258,660 | Likes: 77 | Pipeline: text-classification | 2 labels
 2. madhurjindal/Jailbreak-Detector-Large
    Downloads: 54,077 | Likes: 3 | Pipeline: text-classification | 2 labels
 3. protectai/deberta-v3-base-prompt-injection
    Downloads: 29,740 | Likes: 85 | Pipeline: text-classification | 2 labels
 4. jackhhao/jailbreak-classifier
    Downloads: 4,268 | Likes: 22 | Pipeline: text-classification | 2 labels
 5. madhurjindal/Jailbreak-Detector
    Downloads: 672 | Likes: 0 | Pipeline: text-classification | 2 labels
 6. testsavantai/prompt-injection-defender-base-v1-onnx
    Downloads: 500 | Likes: 0 | Pipeline: text-classification | 2 labels
 7. llm-semantic-router/lora_jailbreak_classifier_modernbert-base_model
    Downloads: 440 | Likes: 0 | Pipeline: text-classification | 2 labels
 8. llm-semantic-router/lora_jailbreak_classifier_bert-base-uncased_model
    Downloads: 432 | Likes: 0 | Pipeline: text-classification | 2 labels
 9. llm-semantic-router/lora_jailbreak_classifier_roberta-base_model
    Downloads: 415 | Likes: 0 | Pipeline: text-classification | 2 labels
10. testsavantai/prompt-injection-defender-base-v1
    Downloads: 120 | Likes: 0 | Pipeline: text-classification | 2 labels
```

### 2. Deploy selected models as detectors on RHOAI

Create a secret in your OpenShift project with your Hugging Face token:

```bash
oc create secret generic huggingface-token --from-literal=token=hf_YOUR_TOKEN_HERE
``` 

Apply the detector storage configuration in a suitable namespace

```
oc apply -f prompt-injection/detector-storage.yaml -n YOUR_NAMESPACE
```

This will download five selected models. You can modify the list of models in the `detector-storage.yaml` file before applying it within `models` section of the `initContainers`.

Use `generate-detectors.sh` script to generate deployment configuration for each of the aforementioned models:

```bash
cd prompt-injection
./generate-detectors.sh 
```

This will create deployment YAML files in the `prompt-injection/deployments` folder.

Apply each of the generated deployment files to your OpenShift project:

```bash
oc apply -f deployments -n YOUR_NAMESPACE
```

### 3. Evaluate deployed detectors

- Install the evaluation package:
```
pip install git+https://github.com/m-misiura/guardrails-eval.git
```

- Create a `detectors.yaml` file:

```
detectors:
  - name: "protectai/deberta-v3-base-prompt-injection-v2"
    config:
      api_url: "https://<YOUR_DETECTOR_ENDPOINT>"
      detector_id: "<YOUR_DETECTOR_ID>"
      threshold: 0.5
      auth_token_env: "DETECTOR_TOKEN"
    # you can add multiple detectors
benign_llm:
  api_url: "https://<YOUR_BENIGN_LLM_ENDPOINT>/v1"
  model_name: "<YOUR_BENIGN_LLM_MODEL_NAME>"
  api_key_env: "BENIGN_LLM_API_KEY"  # Environment variable containing API key
  timeout: 30
```

- Set environment variables

```bash
export BENIGN_LLM_API_KEY="YOUR_MAAS_API_KEY"
export DETECTOR_TOKEN=$(oc whoami -t)
```

- run benchmark

```bash
guardrails-eval \
  --detectors detectors.yaml \
  --probe_tags owasp:llm01 \
  --include_inactive \
  --benign_prompts
```