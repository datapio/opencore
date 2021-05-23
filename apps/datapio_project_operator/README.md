# Datapio Project Operator

This project provides a [Kubernetes](https://kubernetes.io) Operator to manage
`Project` resources.

## :mag_right: What is it?

Based on [Tekton](https://tekton.dev) and the
[PipelineRun Server](../datapio_pipelinerun_server/README.md), it allows you to
specify **Github** Post-Commit webhooks, with distinct concurrency settings, to
run your **Continuous Integration / Deployment** pipelines.

Your CI/CD pipelines will be implemented with
[klifter](https://klifter.datapio.co).
