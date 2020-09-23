const sinon = require('sinon')

module.exports = {
  createServer: sinon.stub().returns({
    listen: sinon.stub().returns({
      once: sinon.stub().callsFake((event, callback) => callback())
    })
  })
}
