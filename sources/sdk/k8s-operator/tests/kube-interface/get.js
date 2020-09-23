const { it } = require('mocha')
const { expect } = require('chai')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  it('should get a single resource', async () => {
    const kubectl = new KubeInterface()
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
    const kubectl = new KubeInterface()
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
    const kubectl = new KubeInterface()
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
      expect(err.message).to.equal('Unexpected response from Kubernetes API Server: 404 - "ERROR"')
    }
  })

  it('should throw an error if the apiVersion is invalid', async () => {
    const kubectl = new KubeInterface()
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
      expect(err.message).to.equal('Unknown API: example.com/v1 Unknown')
    }
  })
}
