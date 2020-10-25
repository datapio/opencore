
const ServerFactory = require('./server-factory')
const WebService = require('./web-service')
const KubeInterface = require('./kube-interface')

const defaultHttpApi = (request, response) => {
  response.end('default backend')
}

class Operator {
  constructor({
    api = defaultHttpApi,
    watchers = [],
    serverOptions = {},
    kubeOptions = {},
    ...options
  }) {
    this.kubectl = new KubeInterface(kubeOptions)
    this.api = api
    this.watchers = watchers
    this.options = options

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
