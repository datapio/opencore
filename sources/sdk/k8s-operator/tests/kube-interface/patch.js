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
      expect(err.name).to.equal('KubeError')
      expect(err.details?.resp?.statusCode).to.equal(404)
      expect(err.details?.resp?.body).to.equal('ERROR')
    }
  })

  it('should throw an error if the patchType is invalid', async () => {
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
        },
        patchType: 'invalid'
      })

      throw new Error('no error has been thrown')
    }
    catch (err) {
      expect(err.name).to.equal('KubeError')
      expect(err.details?.patchType).to.equal('invalid')
    }
  })
}
