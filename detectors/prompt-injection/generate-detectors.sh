#!/bin/bash

# Model mapping: HuggingFace path|short name for Kubernetes resources
models=(
  "Intel/toxic-prompt-roberta|toxic-prompt-roberta"
  "codeintegrity-ai/promptguard|promptguard"
  "meta-llama/Llama-Prompt-Guard-2-86M|llama-prompt-guard-2-86m"
  "protectai/deberta-v3-base-prompt-injection-v2|deberta-prompt-injection-v2"
  "testsavantai/prompt-injection-defender-large-v0-onnx|prompt-injection-defender-large-v0"
)

echo "Generating detector YAML files..."

for entry in "${models[@]}"; do
  # Split on pipe character
  hf_path="${entry%%|*}"
  model_name="${entry##*|}"
  model_path=$(basename "$hf_path")

  echo "Creating ${model_name}-detector.yaml"

  # Replace variables in template
  sed -e "s/\${MODEL_NAME}/$model_name/g" \
      -e "s/\${MODEL_PATH}/$model_path/g" \
      detector-template.yaml > "${model_name}-detector.yaml"
done

echo "Done! Generated YAML files:"
ls -1 *-detector.yaml 2>/dev/null || echo "No files generated"
