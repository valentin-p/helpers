# flux execute manaually
flux reconcile source git broker-platform --namespace flux-system

# verify pods and the resource quota
kubectl get pods -n broker-platform
kubectl get resourcequotas -n broker-platform
