const sinon = require('sinon')
const kubectl = require('./kubectl')

module.exports = {
  api: sinon.spy(),
  healthcheck: sinon.stub().resolves(true),
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
