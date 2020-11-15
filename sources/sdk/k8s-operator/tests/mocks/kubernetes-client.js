const { KubeConfig } = require('@kubernetes/client-node')
const { withWorld } = require('test!world')
const sinon = require('sinon')

const makeNamed = (vtable, namedVtable) => {
  const named = () => namedVtable || vtable

  Object.entries(vtable).map(([name, method]) => {
    named[name] = method
  })

  return named
}

const example = makeNamed(
  {
    get: sinon.stub().resolves({ statusCode: 200, body: { items: ['DATA', 'DATA'] } }),
    post: sinon.stub().resolves({ statusCode: 200, body: 'DATA' })
  },
  {
    get: sinon.stub().resolves({ statusCode: 200, body: 'DATA' }),
    patch: sinon.stub().resolves({ statusCode: 200, body: 'DATA' }),
    delete: sinon.stub().resolves({ statusCode: 200, body: 'DATA' })
  }
)

const watchExample = makeNamed({
  getObjectStream: sinon.stub().callsFake(
    () => withWorld(world => world.stream)
  )
})

const failure = makeNamed(
  {
    get: sinon.stub().resolves({ statusCode: 404, body: 'ERROR' }),
    post: sinon.stub().resolves({ statusCode: 404, body: 'ERROR' })
  },
  {
    get: sinon.stub().resolves({ statusCode: 404, body: 'ERROR' }),
    patch: sinon.stub().resolves({ statusCode: 404, body: 'ERROR' }),
    delete: sinon.stub().resolves({ statusCode: 404, body: 'ERROR' })
  }
)

const customresourcedefinitions = makeNamed(
  {
    get: sinon.stub().resolves({ statusCode: 200, body: { items: [
      {
        metadata: {
          name: 'crd1'
        }
      },
      {
        metadata: {
          name: 'crd2'
        }
      }
    ] }}),
    post: sinon.stub().resolves({ statusCode: 200, body: 'DATA' })
  },
  {}
)

const apis = {
  'apiextensions.k8s.io': {
    'v1beta1': {
      customresourcedefinitions
    }
  },
  'example.com': {
    'v1': {
      watch: {
        namespaces: sinon.stub().returns({
          example: watchExample
        }),
        example: watchExample,
      },
      namespaces: sinon.stub().returns({
        example,
        failure
      }),
      example,
      failure
    }
  }
}

class Client {
  constructor() {
    this.loadSpec = sinon.stub().resolves()
    this.apis = apis
    this.api = apis['example.com']
    this.addCustomResourceDefinition = sinon.stub()
  }
}

module.exports = {
  Client,
  KubeConfig
}
