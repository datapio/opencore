# PipelineRun Server

This project provides a [Kubernetes](https://kubernetes.io) Operator to manage
`PipelineRunServer` and `PipelineRunRequest` resources.

## 🔎 What is it?

Based on [Tekton](https://tekton.dev), it allows you to define concurrency
settings to queue your `PipelineRun` resources and handle the management of
dependant Kubernetes resources (such as `PipelineResource` or
`PersistentVolumeClaim` needed by your `Pipeline` resources).

## ⚗️ Example

```yaml
---
apiVersion: datapio.co/v1
kind: PipelineRunServer
metadata:
  name: my-server
  namespace: default
spec:
  max_concurrent_jobs: 1
  history: 10

---
apiVersion: datapio.co/v1
kind: PipelineRunRequest
metadata:
  name: my-request
  namespace: default
spec:
  pipeline: pipeline0
  server: my-server
  extraResources:
    - apiVersion: v1
      kind: ConfigMap
      metadata:
        name: my-request-cmap
      data:
        hello: world
```
