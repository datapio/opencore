const { describe, it, beforeEach, afterEach } = require('mocha')
const { expect } = require('chai')
const sinon = require('sinon')

const { Engine } = require('../src/index')
const amqp = require('amqplib')

describe('Engine', () => {
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
    console.log = mockedConsole.log
    console.error = mockedConsole.error
    console.warn = mockedConsole.warn
  })

  afterEach(() => {
    console.log = consoleObject.log
    console.error = consoleObject.error
    console.warn = consoleObject.warn
  })

  it('should have a default configuration', () => {
    const engine = new Engine()

    expect(engine.options).to.be.deep.equal(engine.defaultOptions)
  })

  it('should declare the exchanges and queues', async () => {
    const engine = new Engine({
      exchanges: {
        'test-exchange': {
          type: 'topic',
          options: {
            durable: true
          }
        }
      },
      queues: {
        'test-queue': {
          bindings: [
            {
              exchange: 'test-exchange',
              routingKey: '#'
            }
          ],
          options: {
            durable: true
          }
        }
      }
    })

    await engine.declare()

    sinon.assert.calledOnce(amqp.connect)
    sinon.assert.calledOnce(amqp.testEnv.conn.createChannel)
    sinon.assert.calledWith(
      amqp.testEnv.channel.assertExchange,
      'test-exchange',
      'topic',
      { durable: true }
    )
  })

  it('should create publishers', async () => {
    const engine = new Engine({
      publishers: {
        'queue_example': {
          queue: 'example'
        },
        'exchange_example': {
          exchange: 'example',
          routingKey: 'example'
        }
      }
    })

    await engine.declare()

    await engine.publishers.queue_example({
      message: 'HELLO',
      props: {}
    })
    await engine.publishers.exchange_example({
      message: 'WORLD',
      props: {}
    })

    const msgA = Buffer.from(JSON.stringify('HELLO'))
    const msgB = Buffer.from(JSON.stringify('WORLD'))
    sinon.assert.calledWith(engine.channel.sendToQueue, 'example', msgA, {})
    sinon.assert.calledWith(engine.channel.publish, 'example', 'example', msgB, {})
  })

  it('should consume messages', async () => {
    const flags = { consumed: false }
    const engine = new Engine({
      consumers: {
        'queue-example': async (publishers, event) => {
          expect(publishers).to.equal(engine.publishers)
          expect(event).to.equal('DATA')
          flags.consumed = true
        }
      }
    })

    await engine.declare()
    await engine.consume()

    sinon.assert.called(engine.channel.consume)
    const args = engine.channel.consume.args
    const [ queue, handler ] = args[args.length - 1]

    expect(queue).to.equal('queue-example')

    const msg = {
      content: Buffer.from(JSON.stringify('DATA'))
    }
    await handler(msg)

    expect(flags.consumed).to.be.true
    sinon.assert.calledWith(engine.channel.ack, msg)
  })

  it('should catch consumer errors', async () => {
    const err = new Error('error')
    const flags = { consumed: false }
    const engine = new Engine({
      consumers: {
        'queue-example': async (publishers, event) => {
          expect(publishers).to.equal(engine.publishers)
          expect(event).to.equal('DATA')
          flags.consumed = true
          throw err
        }
      }
    })

    await engine.declare()
    await engine.consume()

    sinon.assert.called(engine.channel.consume)
    const args = engine.channel.consume.args
    const [ queue, handler ] = args[args.length - 1]

    expect(queue).to.equal('queue-example')

    const msg = {
      content: Buffer.from(JSON.stringify('DATA'))
    }
    await handler(msg)

    expect(flags.consumed).to.be.true
    sinon.assert.calledWith(mockedConsole.error, 'Error:', err)
    sinon.assert.calledWith(engine.channel.nack, msg)
  })

  it('should cancel the consumers on shutdown', async () => {
    const engine = new Engine({
      consumers: {
        'queue-example': async () => {}
      }
    })

    await engine.declare()
    await engine.consume()

    const { conn, channel } = engine
    await engine.shutdown()

    sinon.assert.calledWith(channel.cancel, 'tag')
    sinon.assert.calledOnce(channel.close)
    sinon.assert.calledOnce(conn.close)
  })
})
