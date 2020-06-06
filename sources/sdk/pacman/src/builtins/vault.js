import { promises as fsPromises } from 'fs'
import make_vault_client from 'node-vault'


export default async () => {
  const endpoint = process.env.VAULT_ADDR || 'http://127.0.0.1:8200'
  const role = process.env.VAULT_ROLE || 'default'
  const mount_point = process.env.VAULT_K8S_MOUNT_POINT || ''
  let jwt = process.env.K8S_JWT

  if (!jwt) {
    try {
      const fileHandle = await fsPromises.open('/var/run/secrets/kubernetes.io/serviceaccount/token', 'r')
      jwt = await fileHandle.readFile({ endoding: 'utf-8' })
    }
    catch (err) {
      throw new Error('Missing Kubernetes JSON Web Token')
    }
  }

  const client = make_vault_client({ endpoint })
  await client.kubernetesLogin({ role, jwt, mount_point })

  return {
    requires: [],
    interface: () => client
  }
}
