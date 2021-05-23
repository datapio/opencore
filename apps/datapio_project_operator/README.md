# Datapio Project Operator

This project provides a [Kubernetes](https://kubernetes.io) Operator to manage
`Project` resources.

## 🔎 What is it?

Based on [Tekton](https://tekton.dev) and the **PipelineRun Server**, it allows
you to specify Github Post-Commit webhooks, with distinct concurrency settings,
to run your Continuous Integration / Deployment pipelines.

Your CI/CD pipelines will be implemented with
[klifter](https://klifter.datapio.co).

## ⚗️ Example

```yaml
---
apiVersion: datap.io/v1alpha1
kind: Project
metadata:
  name: my-project
  namespace: default
spec:
  webhooks:
    - name: default
      max_concurrent_jobs: 10
      history: 10
```
