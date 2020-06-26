import { kube } from '@datapio/sdk-k8s-operator'
import { promises as fsPromises } from 'fs'


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

export default async () => {
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
