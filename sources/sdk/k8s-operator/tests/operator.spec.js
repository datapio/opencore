const { describe, it } = require('mocha')
const { expect, use } = require('chai')
use(require('chai-as-promised'))

const { setUp } = require('test!world')
const sinon = require('sinon')
const casual = require('casual')

const { Operator } = require('../src/index')
const kubeFixture =require('./fixtures/kubectl')

describe('Operator', () => {
  beforeEach(setUp)

  it('should create a Web service', () => {
    const operator = new Operator({})

    expect(operator.service.operator).to.be.equal(operator)
  })

  it('should call overloaded callbacks', async () => {
    const operator = new Operator({})

    await operator.initialize()
    await operator.terminate()
  })

  it('should have a default healthcheck returning true', async () => {
    const operator = new Operator({})

    expect(await operator.healthCheck()).to.be.true
  })

  it('should have a default metrics handler returning nothing', async () => {
    const operator = new Operator({})

    expect(await operator.metrics()).to.be.deep.equal({})
  })

  it('should have a default HTTP backend mounted on /api', async () => {
    const request = sinon.spy()
    const response = {
      end: sinon.stub()
    }

    const operator = new Operator({})

    sinon.assert.calledWith(operator.webapp.use, '/api', operator.api)

    operator.api(request, response)
    sinon.assert.calledWith(response.end, 'default backend')
  })

  describe('ApolloServer', () => {
    it('should have a new KubeInterface per authenticated request', async () => {
      const expectedFoo = casual.word
      const context = sinon.stub().resolves({foo: expectedFoo})
      const operator = new Operator({
        apolloOptions: { context },
        kubeOptions: {
          config: kubeFixture.config
        }
      })

      const expectedToken = casual.word
      const req = {
        get: sinon.stub().returns(`Bearer ${expectedToken}`)
      }

      const result = await operator.apollo.options.context({ req })
      sinon.assert.calledOnce(context)
      sinon.assert.calledWith(req.get, 'authorization')

      expect(result.foo).to.equal(expectedFoo)
      const { token } = result.kubectl.config.getCurrentUser()
      expect(token).to.equal(expectedToken)
    })

    it('should fail if no Bearer token is provided', async () => {
      const operator = new Operator({
        kubeOptions: {
          config: kubeFixture.config
        }
      })
      const req = {
        get: sinon.stub()
      }

      const promise = operator.apollo.options.context({ req })
      expect(promise).to.be.rejectedWith(Operator.Error)
    })
  })
})