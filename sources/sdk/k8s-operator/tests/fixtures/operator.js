const sinon = require('sinon')
const kubectl = require('./kubectl')

const webapp = sinon.spy()
webapp.get = sinon.stub()

module.exports = {
  webapp,
  healthCheck: sinon.stub().resolves(true),
  metrics: sinon.stub().resolves({}),
  kubectl,
  initialize: sinon.stub().resolves(),
  terminate: sinon.stub().resolves(),
  watchers: [
    {
      watch: sinon.stub().resolves({ cancel: sinon.stub() })
    }
  ]
}
