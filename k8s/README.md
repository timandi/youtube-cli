# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the YouTube Remote MCP server.

## Prerequisites

- Kubernetes cluster (v1.20+)
- `kubectl` configured to access your cluster
- Docker image built and pushed to a registry (or available locally)

## Quick Deploy

### Using kubectl

```bash
# Deploy all resources
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -l app=youtube-remote
kubectl logs -f deployment/youtube-remote-mcp

# Access the service
kubectl port-forward service/youtube-remote-mcp 8080:8080
```

### Using Kustomize

```bash
# Deploy with kustomize
kubectl apply -k k8s/

# View generated manifest
kubectl kustomize k8s/

# Delete resources
kubectl delete -k k8s/
```

## Components

### ConfigMap (`configmap.yaml`)
- Application configuration
- Environment-specific settings
- Can be overridden per environment

### PersistentVolumeClaim (`persistentvolume.yaml`)
- Persistent storage for YouTube TV pairing configuration
- 1Gi storage (adjust as needed)
- ReadWriteOnce access mode

### Deployment (`deployment.yaml`)
- Single replica (stateful MCP server)
- Security context (non-root user)
- Resource limits and requests
- Health checks (liveness and readiness probes)
- Volume mount for config persistence

### Service (`service.yaml`)
- ClusterIP service (internal access)
- Session affinity for stateful connections
- Port 8080 (adjust if needed)

## Customization

### Environment-Specific Overlays

Create environment-specific configurations using Kustomize overlays:

```bash
# Directory structure
k8s/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

### Resource Limits

Adjust in `deployment.yaml`:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Storage Class

Specify storage class in `persistentvolume.yaml`:

```yaml
spec:
  storageClassName: fast-ssd  # or your storage class name
```

## Initial Pairing

After deployment, pair with your YouTube TV:

```bash
# Get pod name
POD=$(kubectl get pod -l app=youtube-remote -o jsonpath='{.items[0].metadata.name}')

# Execute pairing (interactive)
kubectl exec -it $POD -- python -c "
from remote import YouTubeRemote
import json

remote = YouTubeRemote('remote', 'Remote', 'Remote')
code = input('Enter pairing code from TV: ')
data = remote.pair(code)

with open('/home/ytremote/.config/youtube-remote/config.json', 'w') as f:
    json.dump(data, f)
print('Paired successfully!')
"
```

## Monitoring

### View Logs

```bash
# Follow logs
kubectl logs -f deployment/youtube-remote-mcp

# Last 100 lines
kubectl logs deployment/youtube-remote-mcp --tail=100

# Logs from all pods
kubectl logs -l app=youtube-remote --all-containers=true
```

### Check Health

```bash
# Check pod status
kubectl get pods -l app=youtube-remote

# Describe pod for events
kubectl describe pod -l app=youtube-remote

# Check health probes
kubectl get pod -l app=youtube-remote -o jsonpath='{.items[0].status.conditions}'
```

## Scaling

The MCP server is stateful and should run as a single instance:

```bash
# Ensure single replica
kubectl scale deployment youtube-remote-mcp --replicas=1
```

## Updates

### Rolling Update

```bash
# Update image
kubectl set image deployment/youtube-remote-mcp \
  youtube-remote=youtube-remote:v2

# Watch rollout
kubectl rollout status deployment/youtube-remote-mcp

# Rollback if needed
kubectl rollout undo deployment/youtube-remote-mcp
```

## Troubleshooting

### Pod Not Starting

```bash
# Check events
kubectl describe pod -l app=youtube-remote

# Check logs
kubectl logs -l app=youtube-remote --previous

# Get pod events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Configuration Issues

```bash
# Check configmap
kubectl describe configmap youtube-remote-config

# Check persistent volume
kubectl describe pvc youtube-remote-config-pvc

# Check if volume is bound
kubectl get pvc
```

### Network Issues

```bash
# Test service connectivity
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Inside pod: nc -zv youtube-remote-mcp 8080

# Check service endpoints
kubectl get endpoints youtube-remote-mcp
```

## Security

### Network Policies (Optional)

Create a NetworkPolicy to restrict traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: youtube-remote-netpol
spec:
  podSelector:
    matchLabels:
      app: youtube-remote
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: mcp-client
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443  # YouTube API
```

## Cleanup

```bash
# Delete all resources
kubectl delete -f k8s/

# Or with kustomize
kubectl delete -k k8s/

# Delete PVC (careful - this deletes pairing data!)
kubectl delete pvc youtube-remote-config-pvc
```
