const { expect } = require('chai')
const sinon = require('sinon')
const { make_engine } = require('../src/index.js')
const amqp = require('amqplib')

describe('make_engine', () => {
  it('should connect to AMQP and create a channel', async () => {
    const engine = await make_engine({ url: 'example' })
    await engine.cancel()

    sinon.assert.calledOnceWithExactly(amqp.connect, 'example')
    sinon.assert.calledOnce(amqp.spies.conn.createChannel)
    sinon.assert.calledOnce(amqp.spies.channel.close)
  })

  it('should create publishers and send messages', async () => {
    const engine = await make_engine({
      url: 'example',
      publishers: {
        foo: {
          queue: 'foo'
        }
      }
    })

    expect(engine.publishers).to.include.all.keys('foo')

    await engine.publishers.foo.send('msg')
    sinon.assert.calledWith(amqp.spies.channel.sendToQueue, 'foo', Buffer.from(JSON.stringify('msg')))

    await engine.cancel()
  })

  it('should create consumers and receive messages', async () => {
    const engine = await make_engine({
      url: 'example',
      publishers: {
        foo: {
          queue: 'foo'
        },
      },
      consumers: {
        bar: {
          queue: 'bar',
          handler: async ({ foo }, msg) => {
            await foo.send(msg)
          }
        }
      }
    })

    sinon.assert.calledOnce(amqp.spies.channel.consume)

    await amqp.spies.channel.sendToQueue('bar', Buffer.from(JSON.stringify('hello')))
    sinon.assert.calledWith(amqp.spies.channel.sendToQueue, 'foo', Buffer.from(JSON.stringify('hello')))
    sinon.assert.calledOnce(amqp.spies.channel.ack)

    await engine.cancel()

    sinon.assert.calledOnceWithExactly(amqp.spies.channel.cancel, 'bar')
  })

  it('should throw an error when the handler fails', async () => {
    const engine = await make_engine({
      url: 'example',
      consumers: {
        foo: {
          queue: 'foo',
          handler: async () => {
            throw new Error('hello')
          }
        }
      }
    })

    let error = null

    try {
      await amqp.spies.channel.sendToQueue('foo', Buffer.from(JSON.stringify('hello')))
    }
    catch (err) {
      error = err
    }

    expect(error).to.be.an('Error')
    expect(error.message).to.equals('hello')
    sinon.assert.calledOnce(amqp.spies.channel.reject)

    await engine.cancel()
  })
})
