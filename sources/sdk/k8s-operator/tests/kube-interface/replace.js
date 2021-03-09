const { it } = require('mocha')
const { expect } = require('chai')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  it('should replace a resource', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const resp = await kubectl.replace({
      apiVersion: 'example.com/v1',
      kind: 'Example',
      metadata: {
        namespace: 'default',
        name: 'example'
      },
      spec: {
        foo: 'bar'
      }
    })

    expect(resp).to.equal('DATA')
  })

  it('should throw an error if the replace failed', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    try {
      await kubectl.replace({
        apiVersion: 'example.com/v1',
        kind: 'Failure',
        metadata: {
          namespace: 'default',
          name: 'example'
        },
        spec: {
          foo: 'bar'
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
}
