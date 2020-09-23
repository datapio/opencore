const { describe, it } = require('mocha')
const { setUp } = require('test!world')

const { expect } = require('chai')
const sinon = require('sinon')

const CancelScope = require('../src/cancel-scope')

module.exports = () => {
  beforeEach(setUp)

  it('should execute the closure', () => {
    const closure = sinon.stub()
    const cancelScope = new CancelScope(closure)
    cancelScope.cancel()

    sinon.assert.calledOnce(closure)
  })

  it('should not catch errors', () => {
    const closure = sinon.stub().throws(new Error('error'))
    const cancelScope = new CancelScope(closure)

    try {
      cancelScope.cancel()
    }
    catch (err) {
      expect(err).to.be.an('Error')
      expect(err.message).to.equal('error')
    }
    finally {
      sinon.assert.threw(closure)
    }
  })
}
