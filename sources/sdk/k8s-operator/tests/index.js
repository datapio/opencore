const { make_operator, adopt_resource } = require('../src/index.js')
const { make_kubectl } = require('../src/kube.js')
const { expect } = require('chai')
const sinon = require('sinon')

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
const breakpoint = () => sleep(0)

describe('make_operator', () => {
  it('should initialize and terminate correctly', async () => {
    const init = sinon.stub()
    const free = sinon.stub()

    const operator = await make_operator({
      lifecycle: {
        initialize: async () => {
          init()
        },
        terminate: async () => {
          free()
        }
      }
    })

    operator.cancel()
    await operator.join()

    sinon.assert.calledOnce(init)
    sinon.assert.calledOnce(free)
  })

  it('should watch resources', async () => {
    const added = sinon.stub().callsFake(async () => {})
    const modified = sinon.stub().callsFake(async () => {})
    const deleted = sinon.stub().callsFake(async () => {})

    const operator = await make_operator({
      watches: [
        {
          apiVersion: 'v1',
          kind: 'Example',
          namespace: 'default',
          on: {
            added,
            modified,
            deleted
          }
        }
      ]
    })

    await breakpoint()
    await operator.kubectl.client.test_stream.push('data', {
      type: 'added',
      object: {
        apiVersion: 'v1',
        kind: 'Example',
        metadata: {
          name: 'foo',
          namespace: 'default'
        }
      }
    })
    await operator.kubectl.client.test_stream.push('data', {
      type: 'modified',
      object: {
        apiVersion: 'v1',
        kind: 'Example',
        metadata: {
          name: 'foo',
          namespace: 'default'
        },
        spec: {
          foo: 'bar'
        }
      }
    })
    await operator.kubectl.client.test_stream.push('data', {
      type: 'deleted',
      object: {
        apiVersion: 'v1',
        kind: 'Example',
        metadata: {
          name: 'foo',
          namespace: 'default'
        },
        spec: {
          foo: 'bar'
        }
      }
    })

    operator.cancel()
    await operator.join()

    sinon.assert.calledOnce(operator.kubectl.client.api.v1.example.watch.namespaces)
    sinon.assert.calledOnce(operator.kubectl.client.api.v1.example.watch.namespaces('default').getObjectStream)
    sinon.assert.calledOnce(added)
    sinon.assert.calledOnce(modified)
    sinon.assert.calledOnce(deleted)
  })
})

describe('kubectl', () => {
  it('should create a client', async () => {
    const kubectl = await make_kubectl()
    sinon.assert.calledOnce(kubectl.client.loadSpec)
  })

  it('should create a resource', async () => {
    const kubectl = await make_kubectl()
    const resp = await kubectl.create({
      apiVersion: 'v1',
      kind: 'Example',
      metadata: {
        name: 'foo',
        namespace: 'default'
      }
    })

    expect(resp).to.deep.equals(['TEST'])
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces)
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces('default').post)
  })

  it('should list resources', async () => {
    const kubectl = await make_kubectl()
    const resp = await kubectl.list({
      apiVersion: 'v1',
      kind: 'Example',
      namespace: 'default'
    })

    expect(resp).to.be.an('Array')
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces)
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces('default').get)
  })

  it('should get a resource', async () => {
    const kubectl = await make_kubectl()
    const resp = await kubectl.get({
      apiVersion: 'v1',
      kind: 'Example',
      namespace: 'default',
      name: 'foo'
    })

    expect(resp).to.be.an('Object')
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces)
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces('default'))
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces('default')('foo').get)
  })

  it('should patch a resource', async () => {
    const kubectl = await make_kubectl()
    const resp = await kubectl.patch({
      apiVersion: 'v1',
      kind: 'Example',
      namespace: 'default',
      name: 'foo',
      patch: null
    })

    expect(resp).to.be.an('Object')
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces)
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces('default'))
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces('default')('foo').patch)
  })

  it('should delete a resource', async () => {
    const kubectl = await make_kubectl()
    const resp = await kubectl.delete({
      apiVersion: 'v1',
      kind: 'Example',
      namespace: 'default',
      name: 'foo'
    })

    expect(resp).to.be.an('Object')
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces)
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces('default'))
    sinon.assert.calledOnce(kubectl.client.api.v1.example.namespaces('default')('foo').delete)
  })

  it('should wait for a condition to be true', async () => {
    const kubectl = await make_kubectl()

    const callback = sinon.stub().callsFake(async obj => ({ condition: obj, res: obj }))
    const waiter = kubectl.wait_condition({
      apiVersion: 'v1',
      kind: 'Example',
      namespace: 'default',
      name: 'foo',
      callback
    })

    await breakpoint()

    await kubectl.client.test_stream.push('data', {
      type: 'added',
      object: false
    })
    await kubectl.client.test_stream.push('data', {
      type: 'modified',
      object: true
    })
    const result = await waiter

    expect(result).to.be.true
    sinon.assert.calledTwice(callback)
    sinon.assert.calledOnce(kubectl.client.test_stream.destroy)
  })

  it('should throw an error on wrong response', async () => {
    const kubectl = await make_kubectl()
    kubectl.client.test_resps.get_single.statusCode = 404
    kubectl.client.test_resps.get_single.body = 'Not Found'

    let error = null

    try {
      await kubectl.get({
        apiVersion: 'v1',
        kind: 'Example',
        name: 'foo',
        namespace: 'default'
      })
    }
    catch (err) {
      error = err
    }

    expect(error).to.be.an('Error')
    expect(error.message).to.equals('Unexpected response from Kubernetes API Server: 404 - "Not Found"')
  })
})

describe('adopt_resource', () => {
  it('should add an owner reference', () => {
    const owner = {
      apiVersion: 'v1',
      kind: 'Example',
      metadata: {
        name: 'foo',
        uid: 'uid'
      }
    }

    const resource = {
      apiVersion: 'v1',
      kind: 'Example',
      metadata: {
        name: 'bar'
      }
    }

    const result = adopt_resource(owner, resource)

    expect(result.metadata.ownerReferences).to.have.lengthOf(1)
    expect(result.metadata.ownerReferences[0].apiVersion).to.equals(owner.apiVersion)
    expect(result.metadata.ownerReferences[0].kind).to.equals(owner.kind)
    expect(result.metadata.ownerReferences[0].name).to.equals(owner.metadata.name)
    expect(result.metadata.ownerReferences[0].uid).to.equals(owner.metadata.uid)
  })
})
