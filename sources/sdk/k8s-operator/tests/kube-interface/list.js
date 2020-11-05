const { it } = require('mocha')
const { expect } = require('chai')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  it('should list resources', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const resp = await kubectl.list({
      apiVersion: 'example.com/v1',
      kind: 'Example',
      namespace: 'default',
      labels: { 'foo': 'bar' }
    })

    expect(resp).to.deep.equal(['DATA', 'DATA'])
  })

  it('should throw an error if listing failed', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    try {
      await kubectl.list({
        apiVersion: 'example.com/v1',
        kind: 'Failure',
        namespace: 'default',
        labels: { 'foo': 'bar' }
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
