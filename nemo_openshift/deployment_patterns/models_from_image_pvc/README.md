## NeMo Guardrails Deployment

### Setup Instructions

#### 0. Create Persistent Volume Claim

```bash
oc apply -f 01-pvc.yaml
```

#### 1. Configure your credentials

Edit the `.env` file with your credentials:

```bash
API_KEY="your-api-key-here"
OPENAI_API_BASE="your-openai-api-base-url"
MODEL_NAME="your-model-name"
```

#### 2. Deploy

```bash
# Load environment variables and apply with variable substitution
set -a && source .env && set +a
envsubst '$API_KEY $OPENAI_API_BASE $MODEL_NAME' < 02_configmap.yaml | oc apply -f -
oc apply -f 03-deployment.yaml
```

### File Structure

```
.
├── 01_pvc.yaml        # Persistent Volume Claim for model storage
├── 02_configmap.yaml  # ConfigMap with config.yaml, rails.co, actions.py
├── 03_deployment.yaml # Kubernetes Deployment, Service, Route  
├── .env               # Credentials (gitignored)
└── README.md
```