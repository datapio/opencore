const { it } = require('mocha')
const { expect } = require('chai')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  it('should get a single resource', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const resp = await kubectl.get({
      apiVersion: 'example.com/v1',
      kind: 'Example',
      namespace: 'default',
      name: 'example'
    })

    expect(resp).to.equal('DATA')
  })

  it('should get a core resource', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const resp = await kubectl.get({
      apiVersion: 'v1',
      kind: 'Example',
      namespace: 'default',
      name: 'example'
    })

    expect(resp).to.equal('DATA')
  })

  it('should throw an error if fetching failed', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    try {
      await kubectl.get({
        apiVersion: 'example.com/v1',
        kind: 'Failure',
        namespace: 'default',
        name: 'example'
      })

      throw new Error('no error has been thrown')
    }
    catch (err) {
      expect(err.name).to.equal('KubeError')
      expect(err.details.resp.statusCode).to.equal(404)
      expect(err.details.resp.body).to.equal('ERROR')
    }
  })

  it('should throw an error if the apiVersion is invalid', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    try {
      await kubectl.get({
        apiVersion: 'example.com/v1',
        kind: 'Unknown',
        namespace: 'default',
        name: 'example'
      })

      throw new Error('no error has been thrown')
    }
    catch (err) {
      expect(err.name).to.equal('KubeError')
      expect(err.details.meta.apiGroup).to.equal('example.com')
      expect(err.details.meta.resourceVersion).to.equal('v1')
      expect(err.details.meta.kind).to.equal('Unknown')
      expect(err.details.meta.namespace).to.equal('default')
      expect(err.details.meta.name).to.equal('example')
      expect(err.details.err).to.be.an('error')
    }
  })
}
