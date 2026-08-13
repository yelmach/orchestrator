kubectl get all -o wide
kubectl get hpa -w
kubectl get pods -w
kubectl get pvc
kubectl get secrets -o json
kubectl get endpoints

kubectl top pods
# Shows you exactly how much CPU and Memory (RAM) your pods and nodes are currently consuming.

kubectl describe pod <pod-name>
kubectl logs <pod-name>

kubectl get events --sort-by='.lastTimestamp'

kubectl exec -it <pod-name> -- sh
su-exec postgres psql


kubectl rollout restart deployment/inventory-app
# If you push a new Docker image to your repository with the latest tag

kubectl delete pod <pod-name>
kubectl delete statefulset billing-db
kubectl delete pvc billing-db-data-billing-db-0
kubectl delete all -l app=inventory-db

kubectl delete all,pvc,secrets,hpa --all