## NeMo Guardrails - emptyDir (No PVC)

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
set -a && source .env && set +a
envsubst '$API_KEY $OPENAI_API_BASE $MODEL_NAME' < 01-configmap.yaml | oc apply -f -
oc apply -f 02-deployment.yaml
```

**Important:** Specify exact variables to envsubst to preserve Colang variables.

### File Structure

```
.
├── 01-configmap.yaml  # ConfigMap with config.yaml, rails.co, actions.py
├── 02-deployment.yaml # Deployment with init container + emptyDir
├── .env               # Credentials (gitignored)
└── README.md
```