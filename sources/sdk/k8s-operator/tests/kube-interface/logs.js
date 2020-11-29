const { it } = require('mocha')
const { expect } = require('chai')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  it('should return pods logs', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const logs = await kubectl.logs({
      name: 'mypod',
      namespace: 'example',
      container: 'main'
    })

    expect(logs).to.equal('DATA')
  })

  it('should throw an error if fetching logs failed', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    try {
      await kubectl.logs({
        namespace: 'failure',
        name: 'mypod',
        container: 'main'
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
