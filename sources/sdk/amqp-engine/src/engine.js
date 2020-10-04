const mergeOptions = require('merge-options').bind({ ignoreUndefined: true });
const amqp = require('amqplib')

const CancelScope = require('./cancel-scope')
const Exchange = require('./exchange')
const Queue = require('./queue')

const encode = msg => Buffer.from(JSON.stringify(msg))

class Engine {
  defaultOptions = {
    url: 'amqp://guest:guest@localhost:5672/',
    exchanges: {},
    queues: {},
    publishers: {},
    consumers: {}
  }

  defaultExchange = {
    type: 'topic',
    options: {
      durable: false
    }
  }

  defaultQueue = {
    bindings: [],
    options: {
      durable: false
    }
  }

  defaultQueueBinding = {
    exchange: 'default',
    routingKey: '#'
  }

  constructor(options) {
    this.options = mergeOptions(this.defaultOptions, options)

    this.conn = null
    this.channel = null

    this.exchanges = {}
    this.queues = {}
    this.publishers = {}

    this.cancelScopes = []
  }

  async declare() {
    this.conn = await amqp.connect(this.options.url)
    this.channel = await this.conn.createChannel()

    // create exchanges
    this.exchanges = Object.fromEntries(
      await Promise.all(
        Object.entries(this.options.exchanges).map(async ([name, config]) => {
          const { type, options } = mergeOptions(this.defaultExchange, config)
          await this.channel.assertExchange(name, type, options)

          return [name, new Exchange(this.channel, name)]
        })
      )
    )

    // create queues
    this.queues = Object.fromEntries(
      await Promise.all(
        Object.entries(this.options.queues).map(async ([name, config]) => {
          const { bindings, options } = mergeOptions(this.defaultQueue, config)
          await this.channel.assertQueue(name, options)

          // bind queues
          await Promise.all(
            bindings.map(async binding => {
              const { exchange, routingKey } = mergeOptions(
                this.defaultQueueBinding,
                binding
              )

              await this.channel.bindQueue(name, exchange, routingKey)
            })
          )

          return [name, new Queue(this.channel, name)]
        })
      )
    )

    // create publishers
    this.publishers = Object.fromEntries(
      Object.entries(this.options.publishers).map(([name, config]) => {
        return [
          name,
          async ({ message, props }) => {
            if ('queue' in config) {
              await this.channel.sendToQueue(
                config.queue,
                encode(message),
                props
              )
            }
            else {
              await this.channel.publish(
                config.exchange,
                config.routingKey,
                encode(message),
                props
              )
            }
          }
        ]
      })
    )

    await this.afterDeclare()
  }

  async consume() {
    await this.beforeConsume()

    this.cancelScopes = await Promise.all(
      Object.entries(this.options.consumers).map(async ([queue, handler]) => {
        const { consumerTag } = await this.channel.consume(
          queue,
          async message => {
            const event = JSON.parse(message.content.toString('utf-8'))

            try {
              await handler(this.publishers, event)
              await this.channel.ack(message)
            }
            catch (err) {
              console.error('Error:', err)
              await this.channel.nack(message)
            }
          }
        )

        return new CancelScope(
          async () => await this.channel.cancel(consumerTag)
        )
      })
    )
  }

  async shutdown() {
    await this.beforeShutdown()

    await Promise.all(
      this.cancelScopes.map(
        async cancelScope => await cancelScope.cancel()
      )
    )

    this.cancelScopes = []

    await this.channel.close()
    await this.conn.close()

    this.channel = null
    this.conn = null
  }

  async afterDeclare() {}

  async beforeConsume() {}

  async beforeShutdown() {}
}

module.exports = Engine
