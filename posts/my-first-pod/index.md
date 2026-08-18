---
title: My First Kubernetes Pod
post_status: publish
post_excerpt: Documenting my first kubectl apply and what I learned.
featured_image: _images/my-first-pod/pod-diagram.png
taxonomy:
    category:
        - kubernetes
        - learning
    post_tag:
        - kubectl
        - pods
        - beginner
---

## What I did today

Ran my first `kubectl apply` and watched the Pod come to life.

![kubectl get pods output](/_images/my-first-pod/kubectl-output.png "kubectl get pods output")

### The manifest I used

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-first-pod
spec:
  containers:
    - name: nginx
      image: nginx:latest
```

### What I learned

A Pod is the smallest deployable unit in Kubernetes. It can hold one or
more containers that share the same network namespace and storage.

Next step: understanding how Deployments manage Pods for me automatically.
