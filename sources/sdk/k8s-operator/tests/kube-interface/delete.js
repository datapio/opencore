const { it } = require('mocha')
const { expect } = require('chai')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  it('should delete a resource', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const resp = await kubectl.delete({
      apiVersion: 'example.com/v1',
      kind: 'Example',
      namespace: 'default',
      name: 'example'
    })

    expect(resp).to.equal('DATA')
  })

  it('should throw an error if the delete failed', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    try {
      await kubectl.delete({
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
}
