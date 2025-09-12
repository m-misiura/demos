## Manual setup

If you deploy the orchestrator with oauth manually, e.g. 

```
oc apply -f orch-ouath.yaml
```

you need to manually add the certs for the detectors you want to use. The orchestrator deployment will initially error out, before you patch it.


For example, for the ibm-hap-38m-detector:
```
oc get configmap openshift-service-ca.crt -o jsonpath='{.data.service-ca\.crt}' > service-ca.crt
```

```
oc create secret generic ca-tls --from-file=service-ca.crt=service-ca.crt
```

```
oc patch deployment guardrails-orchestrator --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "ibm-hap-38m-tls",
      "secret": { "secretName": "ibm-hap-38m-detector-predictor-serving-cert" }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "ca-tls",
      "secret": { "secretName": "ca-tls" }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "ibm-hap-38m-tls",
      "mountPath": "/etc/tls/ibm-hap-38m",
      "readOnly": true
    }
  }
]'
```



