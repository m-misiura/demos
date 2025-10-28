#!/bin/bash

# Model mapping: HuggingFace path|short name for Kubernetes resources
models=(
  "protectai/deberta-v3-base-prompt-injection-v2|deberta-v3-base-prompt-injection-v2"
  "madhurjindal/Jailbreak-Detector-Large|Jailbreak-Detector-Large"
  "jackhhao/jailbreak-classifier|jailbreak-classifier"
  "testsavantai/prompt-injection-defender-base-v1|prompt-injection-defender-base-v1"
  "llm-semantic-router/lora_jailbreak_classifier_modernbert-base_model|lora_jailbreak_classifier_modernbert-base_model"
)

# Create deployments directory if it doesn't exist
mkdir -p deployments

echo "Generating detector YAML files in deployments/ directory..."

for entry in "${models[@]}"; do
  # Split on pipe character
  hf_path="${entry%%|*}"
  model_name="${entry##*|}"
  model_path=$(basename "$hf_path")

  echo "Creating deployments/${model_name}-detector.yaml"

  # Replace variables in template
  sed -e "s/\${MODEL_NAME}/$model_name/g" \
      -e "s/\${MODEL_PATH}/$model_path/g" \
      detector-template.yaml > "deployments/${model_name}-detector.yaml"
done

echo "Done! Generated YAML files:"
ls -1 deployments/*-detector.yaml 2>/dev/null || echo "No files generated"
