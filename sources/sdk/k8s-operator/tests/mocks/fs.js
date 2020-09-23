const sinon = require('sinon')

module.exports = {
  readFileSync: sinon.stub().returns('DATA')
}
