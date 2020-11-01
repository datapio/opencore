const { it } = require('mocha')
const { expect } = require('chai')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  it('should patch a resource', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const resp = await kubectl.patch({
      apiVersion: 'example.com/v1',
      kind: 'Example',
      namespace: 'default',
      name: 'example',
      patch: {
        spec: { foo: 'bar' }
      }
    })

    expect(resp).to.equal('DATA')
  })

  it('should throw an error if the patch failed', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    try {
      await kubectl.patch({
        apiVersion: 'example.com/v1',
        kind: 'Failure',
        namespace: 'default',
        name: 'example',
        patch: {
          spec: { foo: 'bar' }
        }
      })

      throw new Error('no error has been thrown')
    }
    catch (err) {
      expect(err.message).to.equal('Unexpected response from Kubernetes API Server: 404 - "ERROR"')
    }
  })
}
