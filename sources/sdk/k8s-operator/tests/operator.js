const { describe, it } = require('mocha')
const { setUp } = require('test!world')
const { expect } = require('chai')
const sinon = require('sinon')

const { Operator } = require('../src/index')

module.exports = () => {
  beforeEach(setUp)

  it('should create an API service', () => {
    const operator = new Operator()

    expect(operator.service.operator).to.be.equal(operator)
  })

  it('should call overloaded callbacks', async () => {
    const operator = new Operator()

    await operator.initialize()
    await operator.terminate()
  })

  it('should have a default healthcheck returning true', async () => {
    const operator = new Operator()

    expect(await operator.healthcheck()).to.be.true
  })

  it('should have a default metrics handler returning nothing', async () => {
    const operator = new Operator()

    expect(await operator.metrics()).to.be.deep.equal({})
  })

  it('should have a default HTTP backend', async () => {
    const request = sinon.spy()
    const response = {
      end: sinon.stub()
    }

    const operator = new Operator()
    operator.api(request, response)

    sinon.assert.calledWith(response.end, 'default backend')
  })
}
