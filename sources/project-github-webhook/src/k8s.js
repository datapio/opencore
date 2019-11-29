import { Client } from 'kubernetes-client'
import deploymentManifest from './github-webhook-deployment.json'

/*
 * let kubernetes-client configure automatically by trying the KUBECONFIG
 * environment variable first, then ~/.kube/config, then an in-cluster service
 * account, and lastly settling on a default proxy configuration
 */
const client = new Client({ version: '1.13' })

const { post } = client.api.v1.namespaces('default').deployments

export default () => post({ body: deploymentManifest })
