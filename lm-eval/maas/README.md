## Set up secrets for the MaaS deployment

Source the environment variables from .env and create the secret (only API key needs to be in secret):

```bash
source .env

oc create secret generic phi4-config --from-literal=api-key="${API_KEY}"
```

The `.env` file should look like this (do not commit it to version control):

```
export MODEL_NAME="ACTUAL_MODEL_NAME"
export ROUTE="https://BASE_URL"
export API_KEY="API_KEY"
```

## Run lm-eval with MaaS

Use `envsubst` to substitute MODEL_NAME and ROUTE before applying:

```bash
envsubst < lmeval-job.yaml | oc apply -f -
```
