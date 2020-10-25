const mergeOptions = require('merge-options').bind({ ignoreUndefined: true })
const { ApolloServer } = require('apollo-server-express')
const kubernetes = require('kubernetes-client')
const express = require('express')

const ServerFactory = require('./server-factory')
const WebService = require('./web-service')
const KubeInterface = require('./kube-interface')


const defaultHttpApiFactory = () =>
  (request, response) => {
    response.end('default backend')
  }

const getAuthBearer = header => {
  if (!header.startsWith('Bearer ')) {
    throw new Error('Invalid token')
  }

  return header.substring(7, header.length);
}

class Operator {
  defaultApolloOptions = {
    typeDefs: [],
    resolvers: {},
    context: () => ({})
  }

  constructor({
    apiFactory = defaultHttpApiFactory,
    watchers = [],
    serverOptions = {},
    kubeOptions = {},
    apolloOptions = {},
    ...options
  }) {
    this.watchers = watchers
    this.options = options

    this.kubectl = new KubeInterface(kubeOptions)

    this.api = apiFactory(this.kubectl)
    this.webapp = express()
    this.webapp.use('/api', this.api)

    const apolloRealOptions = mergeOptions(this.defaultApolloOptions, apolloOptions)
    const userContext = apolloRealOptions.context
    apolloRealOptions.context = async ({ req, ...args }) => {
      const ctx = await userContext({ req, ...args })

      const kubeConfig = new kubernetes.KubeConfig()
      kubeConfig.addCluster(this.kubectl.config.getCurrentCluster())
      kubeConfig.addUser({
        name: 'graphql-client',
        token: getAuthBearer(req.get('authorization'))
      })
      kubeConfig.addContext({
        cluster: kubeConfig.getCurrentCluster().name,
        name: 'graphql-request',
        user: 'graphql-client',
        namespace: kubeConfig.getCurrentContextObject().namespace
      })
      kubeConfig.setCurrentContext('graphql-request')

      const kubectl = new KubeInterface({
        crds: this.kubectl.crds,
        config: kubeConfig
      })
      await kubectl.load()

      return {
        kubectl,
        ...ctx
      }
    }

    const apolloServer = new ApolloServer(apolloRealOptions)
    apolloServer.applyMiddleware({
      app: this.webapp,
      path: '/graphql'
    })

    const serverFactory = new ServerFactory(serverOptions)
    this.service = new WebService(this, serverFactory)
  }

  async initialize() {}

  async terminate() {}

  async healthCheck() {
    return true
  }

  async metrics() {
    return {}
  }
}

module.exports = Operator
