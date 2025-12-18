If LoadBalancer IP is not available, annotate the Gateway to use a NodePort Service

```bash
kubectl annotate gateways.gateway.networking.k8s.io -n openshift-ingress openshift-ai-inference networking.istio.io/service-type=NodePort --overwrite
```