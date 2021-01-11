/**
 * Apollo Server context factory
 *
 * @module graphql/context
 */

/**
 * Create a new Apollo Server context handler.
 *
 * @param {Operator} operator Operator owning the Apollo Server
 * @param {Function} userContext User supplied context handler
 * @returns {Function} Context handler with Kubernetes authentication support
 */

module.exports = (operator, userContext) => async ({ req, res, ...args }) => {
  const ctx = await userContext({ req, res, ...args })

  const kubeConfig = new kubernetes.KubeConfig()

  kubeConfig.loadFromString(
    JSON.stringify({
      apiVersion: 'v1',
      kind: 'Config',
      clusters: [],
      users: [],
      contexts: [],
      'current-context': ''
    })
  )

  kubeConfig.addCluster(operator.kubectl.config.getCurrentCluster())

  const token = authTokenProcessor(req, res)

  kubeConfig.addUser({
    name: 'graphql-client',
    token
  })
  kubeConfig.addContext({
    cluster: operator.kubectl.config.getCurrentCluster().name,
    name: 'graphql-request',
    user: 'graphql-client',
    namespace: operator.kubectl.config.getCurrentContextObject().namespace
  })
  kubeConfig.setCurrentContext('graphql-request')

  const kubectl = new KubeInterface({
    crds: operator.kubectl.crds,
    createCRDs: false,
    config: kubeConfig
  })
  await kubectl.load()

  return {
    kubectl,
    ...ctx
  }
}
