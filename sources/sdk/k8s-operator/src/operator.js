const mergeOptions = require('merge-options').bind({ ignoreUndefined: true })
const { ApolloServer } = require('apollo-server-express')
const kubernetes = require('kubernetes-client')
const express = require('express')
const cookieParser = require('cookie-parser')

const crypto = require('crypto')

const ServerFactory = require('./server-factory')
const WebService = require('./web-service')
const KubeInterface = require('./kube-interface')
const makeApolloContext = require('./graphql/context')

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

const authTokenProcessorFactory = name => (req, res) => {
  const signedCookie = () => req.signedCookies[name]
  const authHeader = () => {
    const authorization = req.get('authorization')
    if (authorization && !authorization.startsWith('Bearer ')) {
      throw new OperatorError(
        'Invalid Authorization header. \'Bearer\' expected'
      )
    }
    return authorization?.substring(7)
  }
  const getToken = () => authHeader() || signedCookie() || null
  const setToken = token => res.setHeader(
    'Set-Cookie', `${name}=${token}; HttpOnly`
  )
  const token = getToken()
  if (!token) {
    throw new OperatorError('Missing token')
  }
  setToken(token)
  return token
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

    const authTokenProcessor = authTokenProcessorFactory(authCookieName)

    apolloRealOptions.context = makeApolloContext(
      this,
      apolloRealOptions.context
    )

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
