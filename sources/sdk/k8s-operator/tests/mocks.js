const mock = require('mock-require')
const sinon = require('sinon')

const k8s = sinon.spy()

const client_factory = {}
client_factory.make = function make () {
  this.loadSpec = sinon.stub().callsFake(async () => {})

  this.test_stream = {
    callbacks: {},
    on (ev, cb) {
      this.callbacks[ev] = cb
    },
    async push (ev, msg) {
      const cb = this.callbacks[ev] || (async () => {})
      await cb(msg)
    },
    destroy: sinon.stub()
  }

  const resps = {
    get_single: {
      statusCode: 200,
      body: {}
    },
    get_many: {
      statusCode: 200,
      body: {
        items: []
      }
    },
    post: {
      statusCode: 200,
      body: 'TEST'
    },
    patch: {
      statusCode: 200,
      body: {}
    },
    delete: {
      statusCode: 200,
      body: {}
    }
  }
  this.test_resps = resps
  this.test_named_resource = {
    get: sinon.stub().callsFake(async () => resps.get_single),
    post: sinon.stub().callsFake(async () => resps.post),
    patch: sinon.stub().callsFake(async () => resps.patch),
    delete: sinon.stub().callsFake(async () => resps.delete),
    getObjectStream: sinon.stub().returns(this.test_stream)
  }

  const root_endpoint = sinon.stub().returns(this.test_named_resource)
  root_endpoint.get = sinon.stub().callsFake(async () => resps.get_many)
  root_endpoint.post = sinon.stub().callsFake(async () => resps.post)
  root_endpoint.patch = sinon.stub().callsFake(async () => resps.patch)
  root_endpoint.delete = sinon.stub().callsFake(async () => resps.delete)

  const namespaced_endpoint = sinon.stub().returns(this.test_named_resource)
  namespaced_endpoint.get = sinon.stub().callsFake(async () => resps.get_many)
  namespaced_endpoint.post = sinon.stub().callsFake(async () => resps.post)
  namespaced_endpoint.patch = sinon.stub().callsFake(async () => resps.patch)
  namespaced_endpoint.delete = sinon.stub().callsFake(async () => resps.delete)
  namespaced_endpoint.getObjectStream = sinon.stub().returns(this.test_stream)
  root_endpoint.namespaces = sinon.stub().returns(namespaced_endpoint)

  const watch_endpoint = sinon.stub().returns(this.test_named_resource)
  watch_endpoint.namespaces = sinon.stub().returns(namespaced_endpoint)
  watch_endpoint.getObjectStream = sinon.stub().returns(this.test_stream)
  root_endpoint.watch = watch_endpoint

  this.api = {
    v1: {
      example: root_endpoint
    }
  }
}

k8s.Client = sinon.stub(client_factory, 'make')
  .callThroughWithNew()

mock('kubernetes-client', k8s)
