const { setUp } = require('test!world')
const { it } = require('mocha')
const sinon = require('sinon')

const { KubeInterface } = require('../../src/index')

module.exports = () => {
  beforeEach(setUp)

  it('should create a client a load the server API specification', async () => {
    const kubectl = new KubeInterface()
    await kubectl.load()

    sinon.assert.calledOnce(kubectl.client.loadSpec)
  })

  require('./create')()
  require('./list')()
  require('./get')()
  require('./watch')()
  require('./patch')()
  require('./delete')()
}
