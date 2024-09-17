# list deployemtns adn restart of of the deployment
kubectl get deployments -n broker-platform
kubectl rollout restart deployment/my-deployment -n broker-platform


# Get limits for this namespace/cluster
kubectl get limits -n broker-platform -o custom-columns=RESOURCES:.spec.limits
