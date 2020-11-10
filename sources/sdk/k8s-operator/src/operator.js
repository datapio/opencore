const mergeOptions = require('merge-options').bind({ ignoreUndefined: true })
const { ApolloServer } = require('apollo-server-express')
const kubernetes = require('kubernetes-client')
const express = require('express')
const cookieParser = require('cookie-parser')

const crypto = require('crypto')

const ServerFactory = require('./server-factory')
const WebService = require('./web-service')
const KubeInterface = require('./kube-interface')

class OperatorError extends Error {
  constructor(msg) {
    super(msg)
    this.name = this.constructor.name
    Error.captureStackTrace(this, this.constructor)
  }
}

const defaultHttpApiFactory = () =>
  (request, response) => {
    response.end('default backend')
  }

const makeAuthToken = name => ({
  signedCookie(req) {
    return req.signedCookies[name]
  },
  authHeader(req) {
    const authorization = req.get('authorization')
    return authorization.substring(7, authorization.length)
  },
  get(req) {
    return this.authHeader(req) ||
      this.signedCookie(req) ||
      null
  },
  set(resp, token) {
    resp.setHeader('Set-Cookie', `${name}=${token}; HttpOnly`)
  }
})

class Operator {
  defaultApolloOptions = {
    typeDefs: [],
    resolvers: {},
    context: () => ({})
  }

  Error = OperatorError

  constructor({
    apiFactory = defaultHttpApiFactory,
    watchers = [],
    serverOptions = {},
    kubeOptions = {},
    apolloOptions = {},
    cookieSecret = crypto.randomBytes(48).toString('hex'),
    authCookieName = 'X-Datapio-Auth-Token',
    ...options
  }) {
    this.watchers = watchers
    this.options = options

    this.kubectl = new KubeInterface(kubeOptions)

    this.api = apiFactory(this.kubectl)
    this.webapp = express()
    this.webapp.use(cookieParser(cookieSecret))
    this.webapp.use('/api', this.api)

    const apolloRealOptions = mergeOptions(
      this.defaultApolloOptions,
      apolloOptions
    )

    const userContext = apolloRealOptions.context
    apolloRealOptions.context = async ({ req, resp, ...args }) => {
      const ctx = await userContext({ req, ...args })

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

      kubeConfig.addCluster(this.kubectl.config.getCurrentCluster())

      const authToken = makeAuthToken(authCookieName)

      const token = authToken.get(req)
      if (!token) {
        throw new Error('Invalid token')
      }
      authToken.set(resp, token)

      kubeConfig.addUser({
        name: 'graphql-client',
        token
      })
      kubeConfig.addContext({
        cluster: this.kubectl.config.getCurrentCluster().name,
        name: 'graphql-request',
        user: 'graphql-client',
        namespace: this.kubectl.config.getCurrentContextObject().namespace
      })
      kubeConfig.setCurrentContext('graphql-request')

      const kubectl = new KubeInterface({
        crds: this.kubectl.crds,
        createCRDs: false,
        config: kubeConfig
      })
      await kubectl.load()

      return {
        kubectl,
        ...ctx
      }
    }

    this.apollo = new ApolloServer(apolloRealOptions)
    this.apollo.options = apolloRealOptions
    this.apollo.applyMiddleware({
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
