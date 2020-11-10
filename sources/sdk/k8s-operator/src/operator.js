const mergeOptions = require('merge-options').bind({ ignoreUndefined: true })
const { ApolloServer } = require('apollo-server-express')
const kubernetes = require('kubernetes-client')
const express = require('express')
const cookieParser = require('cookie-parser')

const ServerFactory = require('./server-factory')
const WebService = require('./web-service')
const KubeInterface = require('./kube-interface')

const { COOKIE_SECRET } = process.env
const AUTH_COOKIE_NAME = 'authToken'

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


const getAuthToken = req => {
  let result
  if (AUTH_COOKIE_NAME in req.cookies) {
    result = req.cookies[AUTH_COOKIE_NAME]
  } else if (AUTH_COOKIE_NAME in req.signedCookies) {
    result = req.signedCookies[AUTH_COOKIE_NAME]
  } else {
    const authorization = req.get('authorization')
    if (!(authorization && authorization.startsWith('Bearer '))) {
      throw new OperatorError('Invalid token')
    }
    result = authorization.substring(7, header.length)
  }

  return result
}

const setAuthToken = (resp, token) => {
  resp.setHeader('Set-Cookie', `${AUTH_COOKIE_NAME}=${token}; HttpOnly`)
}

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
    ...options
  }) {
    this.watchers = watchers
    this.options = options

    this.kubectl = new KubeInterface(kubeOptions)

    this.api = apiFactory(this.kubectl)
    this.webapp = express()
    this.webapp.use(cookieParser(COOKIE_SECRET))
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
      
      const token = getAuthToken(req)
            
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

      setAuthToken(resp, token)

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
