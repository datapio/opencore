const ServerFactory = require('./server-factory')
const APIService = require('./api-service')
const KubeInterface = require('./kube-interface')

const defaultHealthcheck = () => Promise.resolve(true)
const defaultMetrics = () => Promise.resolve({})
const defaultHttpApi = (request, response) => {
  response.end('default backend')
}

class Operator {
  constructor(
    healthcheck = defaultHealthcheck,
    metrics = defaultMetrics,
    api = defaultHttpApi,
    watchers = [],
    options = {}
  ) {
    this.kubectl = new KubeInterface()
    this.healthcheck = healthcheck
    this.metrics = metrics
    this.api = api
    this.watchers = watchers

    const serverFactory = new ServerFactory(options)
    this.service = new APIService(this, serverFactory)
  }

  async initialize() {}

  async terminate() {}
}

module.exports = Operator
