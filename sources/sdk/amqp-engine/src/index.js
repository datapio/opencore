const amqp = require('amqplib')


const make_publisher = (channel, { queue }) => ({
  send: async message => {
    await channel.sendToQueue(queue, Buffer.from(JSON.stringify(message)))
  }
})

const make_consumer = async (channel, publishers, { queue, handler }) => {
  const { consumerTag } = await channel.consume(queue, async msg => {
    try {
      await handler(publishers, msg.content)
    }
    catch (err) {
      channel.reject(msg)
      throw err
    }

    channel.ack(msg)
  })

  return {
    cancel: async () => {
      await channel.cancel(consumerTag)
    }
  }
}

const make_engine = async ({ url, publishers, consumers }) => {
  const conn = await amqp.connect(url)
  const channel = await conn.createChannel()

  const publisherObjects = Object.fromEntries(
    await Promise.all(
      Object.keys(publishers).map(
        async name => [
          name,
          await make_publisher(channel, publishers[name])
        ]
      )
    )
  )

  const consumerObjects = Object.fromEntries(
    await Promise.all(
      Object.keys(consumers).map(
        async name => [
          name,
          await make_consumer(channel, publisherObjects, consumers[name])
        ]
      )
    )
  )

  return {
    publishers: publisherObjects,
    cancel: async () => {
      await Promise.all(
        Object.values(consumerObjects).map(async consumer => await consumer.cancel())
      )
      await channel.close()
    }
  }
}

module.exports = { make_engine }
