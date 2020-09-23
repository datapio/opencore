const { it } = require('mocha')
const { expect } = require('chai')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  it('should create resources', async () => {
    const kubectl = new KubeInterface()
    await kubectl.load()

    const resp = await kubectl.create(
      {
        apiVersion: 'example.com/v1',
        kind: 'Example',
        metadata: {
          name: 'example',
          namespace: 'default'
        },
        spec: {}
      }
    )

    expect(resp).to.deep.equal(['DATA'])
  })

  it('should throw an error if creation failed', async () => {
    const kubectl = new KubeInterface()
    await kubectl.load()

    try {
      await kubectl.create(
        {
          apiVersion: 'example.com/v1',
          kind: 'Failure',
          metadata: {
            name: 'example-failure',
            namespace: 'default'
          },
          spec: {}
        }
      )

      throw new Error('no error has been thrown')
    }
    catch (err) {
      expect(err.message).to.equal('Unexpected response from Kubernetes API Server: 404 - "ERROR"')
    }
  })
}
