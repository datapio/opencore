# Release Controller

This component is part of the *Datapio Open Core*. Its purpose is to trigger
deployment pipelines when a new ``Release`` resource is created.

## Example

```yaml
---
apiVersion: datap.io/v1
kind: Release
metadata:
  name: my-repository-sha1
spec:
  repository:
    name: my-repository
    url: https://github.com/my-user/my-repository
  revision: sha1
  environment: integration
  artifacts:
    - name: my-artifact
      type: npm # or docker, or helm
      path: sources/my-artifact
      params: null
```
