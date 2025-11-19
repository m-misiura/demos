## NeMo Guardrails Deployment

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
# Load environment variables and apply with variable substitution
set -a && source .env && set +a
envsubst '$API_KEY $OPENAI_API_BASE $MODEL_NAME' < 01_configmap.yaml | oc apply -f -
oc apply -f 02_deployment.yaml
```

**Important:** The `'$API_KEY $OPENAI_API_BASE $MODEL_NAME'` argument tells envsubst to ONLY substitute these specific variables, preserving Colang variables like `$length_result` and `$forbidden_result`.

### File Structure

```
.
├── 01_configmap.yaml  # ConfigMap with config.yaml, rails.co, actions.py
├── 02_deployment.yaml # Kubernetes Deployment, Service, Route  
├── .env               # Credentials (gitignored)
└── README.md
```