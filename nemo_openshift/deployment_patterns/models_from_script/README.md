## NeMo Guardrails Deployment - Models from Script

### Setup Instructions

#### 1. Configure your credentials

Edit the `.env` file with your credentials:

```bash
API_KEY="your-api-key-here"
OPENAI_API_BASE="your-openai-api-base-url"
MODEL_NAME="your-model-name"
```

#### 2. Deploy

```bash
# Create PVC for models
oc apply -f 01-pvc.yaml

# Load environment variables and deploy ConfigMap with variable substitution
set -a && source .env && set +a
envsubst '$API_KEY $OPENAI_API_BASE $MODEL_NAME' < 02-configmap.yaml | oc apply -f -
oc apply -f 03-deployment.yaml
```

**Important:** The `'$API_KEY $OPENAI_API_BASE $MODEL_NAME'` argument tells envsubst to ONLY substitute these specific variables, preserving Colang variables like `$length_result` and `$forbidden_result`.

### File Structure

```
.
├── 01-pvc.yaml         # PersistentVolumeClaim for model storage
├── 02-configmap.yaml   # ConfigMap with config.yaml, rails.co, actions.py
├── 03-deployment.yaml  # Deployment, Service, and Route (init container downloads models)
├── .env                # Credentials (gitignored)
└── README.md
```
