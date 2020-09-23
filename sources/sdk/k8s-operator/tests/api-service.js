const { describe, it } = require('mocha')
const { setUp } = require('test!world')
const { expect } = require('chai')
const sinon = require('sinon')

const {
  ServerFactory,
  APIService
} = require('../src/index')

const operator = require('./fixtures/operator')
const terminus = require('@godaddy/terminus')

module.exports = () => {
  const consoleObject = {
    log: console.log,
    error: console.error,
    warn: console.warn
  }

  const mockedConsole = {
    log: sinon.stub(),
    error: sinon.stub(),
    warn: sinon.stub()
  }

  beforeEach(() => {
    setUp()

    console.log = mockedConsole.log
    console.error = mockedConsole.error
    console.warn = mockedConsole.warn
  })

  afterEach(() => {
    console.log = consoleObject.log
    console.error = consoleObject.error
    console.warn = consoleObject.warn
  })

  it('should initialize the servers', () => {
    const serverFactory = new ServerFactory()
    const service = new APIService(operator, serverFactory)

    expect(service.servers).to.be.an('array').of.length(1)
    sinon.assert.calledOnce(terminus.createTerminus)
  })

  it('should initialize the operator before starting', async () => {
    const serverFactory = new ServerFactory()
    const service = new APIService(operator, serverFactory)

    await service.beforeListen()

    sinon.assert.calledOnce(operator.kubectl.load)
    sinon.assert.calledOnce(operator.initialize)
    expect(service.cancelScopes).to.be.an('array').of.length(1)
  })

  it('should stop the watchers before shutdown', async () => {
    const serverFactory = new ServerFactory()
    const service = new APIService(operator, serverFactory)

    await service.beforeListen()
    await service.beforeShutdown()

    sinon.assert.calledOnce(service.cancelScopes[0].cancel)
  })

  it('should log a message when a shutdown is requested', async () => {
    const serverFactory = new ServerFactory()
    const service = new APIService(operator, serverFactory)

    await service.shutdownRequested()

    sinon.assert.calledOnce(mockedConsole.log)
  })

  it('should terminate the operator once it is shutdown', async () => {
    const serverFactory = new ServerFactory()
    const service = new APIService(operator, serverFactory)

    await service.shutdownDone()

    sinon.assert.calledOnce(operator.terminate)
  })

  it('should log an error when an exception is thrown during shutdown', async () => {
    const serverFactory = new ServerFactory()
    const service = new APIService(operator, serverFactory)
    const err = new Error('error')

    await service.shutdownFailed(err)

    sinon.assert.calledWith(mockedConsole.error, err)
  })

  it('should log messages sent by terminus', async () => {
    const serverFactory = new ServerFactory()
    const service = new APIService(operator, serverFactory)

    await service.logger('msg', 'payload')

    sinon.assert.calledWith(mockedConsole.log, 'msg', 'payload')
  })

  it('should listen on each server port', async () => {
    const serverFactory = new ServerFactory()
    const service = new APIService(operator, serverFactory)

    await service.listen()
  })
}
