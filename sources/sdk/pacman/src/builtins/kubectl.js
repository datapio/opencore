const { kube } = require('@datapio/sdk-k8s-operator')
const { promises: fsPromises } = require('fs')


const get_namespace = async () => {
  let namespace = process.env.K8S_NAMESPACE

  if (!namespace) {
    try {
      const fileHandle = await fsPromises.open('/var/run/secrets/kubernetes.io/serviceaccount/namespace', 'r')
      namespace = await fileHandle.readFile({ endoding: 'utf-8' })
    }
    catch (err) {
      namespace = 'default'
    }
  }

  return namespace
}

module.exports = async () => {
  const namespace = await get_namespace()
  const kubectl = await kube.make_kubectl()

  return {
    requires: [],
    interface: () => ({
      namespace,
      api: kubectl
    })
  }
}
