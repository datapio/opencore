# Datapio PipelineRun Server

This project provides a [Kubernetes](https://kubernetes.io) Operator to manage
`PipelineRunServer` and `PipelineRunRequest` resources.

## :mag_right: What is it?

Based on [Tekton](https://tekton.dev), it allows you to define concurrency
settings to queue your `PipelineRun` resources and handle the management of
dependant Kubernetes resources (such as `PipelineResource` or
`PersistentVolumeClaim` needed by your `Pipeline` resources).
