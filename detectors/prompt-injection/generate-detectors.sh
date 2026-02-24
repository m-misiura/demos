#!/bin/bash

# Function to sanitize names for Kubernetes
# - Convert to lowercase
# - Replace underscores with hyphens
# - Truncate to 53 chars (leaving room for "-detector" suffix = 63 total)
sanitize_k8s_name() {
  local name="$1"
  # Convert to lowercase, replace underscores with hyphens
  name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
  # Truncate to 53 characters (63 - 10 for "-detector")
  if [ ${#name} -gt 53 ]; then
    name="${name:0:53}"
  fi
  echo "$name"
}

# Model mapping: HuggingFace path|short name for Kubernetes resources
models=(
  "protectai/deberta-v3-base-prompt-injection-v2|deberta-prompt-injection-v2"
  "jackhhao/jailbreak-classifier|jailbreak-classifier"
  "devndeploy/bert-prompt-injection-detector|bert-prompt-injection-detector"
  "madhurjindal/Jailbreak-Detector|jailbreak-detector"
  "llm-semantic-router/mmbert32k-jailbreak-detector-merged|mmbert32k-jailbreak-detector"
)

# Create deployments directory if it doesn't exist
mkdir -p deployments

echo "Generating detector YAML files in deployments/ directory..."

for entry in "${models[@]}"; do
  # Split on pipe character
  hf_path="${entry%%|*}"
  model_name_raw="${entry##*|}"
  model_path=$(basename "$hf_path")

  # Sanitize the model name for Kubernetes compliance
  model_name=$(sanitize_k8s_name "$model_name_raw")

  echo "Creating deployments/${model_name}-detector.yaml (from $model_name_raw)"

  # Replace variables in template
  sed -e "s/\${MODEL_NAME}/$model_name/g" \
      -e "s/\${MODEL_PATH}/$model_path/g" \
      detector-template.yaml > "deployments/${model_name}-detector.yaml"
done

echo "Done! Generated YAML files:"
ls -1 deployments/*-detector.yaml 2>/dev/null || echo "No files generated"
