const { KubeConfig } = require('@kubernetes/client-node')
const { withWorld } = require('test!world')
const sinon = require('sinon')

const mixinGenericEndpoint = (ep, data) => {
  Object.entries(data).map(([verb, response]) => {
    ep[verb] = sinon.stub().resolves(response)
  })
  ep.getObjectStream = sinon.stub().callsFake(() => withWorld(world => world.stream))
}

const mixinWatchEndpoint = ep => {
  ep.watch = ep
}

const namedEndpoints = {
  'example': {},
  'failure': {}
}

mixinGenericEndpoint(namedEndpoints.example, {
  get: { statusCode: 200, body: 'DATA' },
  patch: { statusCode: 200, body: 'DATA' },
  delete: { statusCode: 200, body: 'DATA' }
})

mixinGenericEndpoint(namedEndpoints.failure, {
  get: { statusCode: 404, body: 'ERROR' },
  patch: { statusCode: 404, body: 'ERROR' },
  delete: { statusCode: 404, body: 'ERROR' }
})

const mixinNamespaceEndpoint = (ep, namedEndpoint, data) => {
  const namespacedEndpoint = sinon.stub().returns(namedEndpoint)
  mixinGenericEndpoint(namespacedEndpoint, data)

  ep.namespaces = sinon.stub().returns(namespacedEndpoint)
}

const apis = {
  'example.com': {
    'v1': {
      'example': sinon.stub().returns(namedEndpoints.example),
      'failure': sinon.stub().returns(namedEndpoints.failure)
    }
  }
}

mixinGenericEndpoint(apis['example.com'].v1.example, {
  post: { statusCode: 200, body: 'DATA' },
  get: { statusCode: 200, body: { items: ['DATA', 'DATA'] } }
})
mixinNamespaceEndpoint(apis['example.com'].v1.example, namedEndpoints.example, {
  post: { statusCode: 200, body: 'DATA' },
  get: { statusCode: 200, body: { items: ['DATA', 'DATA'] } }
})
mixinWatchEndpoint(apis['example.com'].v1.example)

mixinGenericEndpoint(apis['example.com'].v1.failure, {
  post: { statusCode: 404, body: 'ERROR' },
  get: { statusCode: 404, body: 'ERROR' }
})
mixinNamespaceEndpoint(apis['example.com'].v1.failure, namedEndpoints.failure, {
  post: { statusCode: 404, body: 'ERROR' },
  get: { statusCode: 404, body: 'ERROR' }
})

class Client {
  constructor() {
    this.loadSpec = sinon.stub().resolves()
    this.apis = apis
    this.api = apis['example.com']
  }
}

module.exports = {
  Client,
  KubeConfig
}
