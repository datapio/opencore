const mock = require('mock-require')
const sinon = require('sinon')

const spies = {
  amqplib: sinon.spy(),
  conn: sinon.spy(),
  channel: sinon.spy()
}

spies.amqplib.spies = spies
spies.amqplib.connect = sinon.stub().callsFake(async () => spies.conn)
spies.conn.createChannel = sinon.stub().callsFake(async () => spies.channel)

spies.channel.queues = {}

spies.channel.sendToQueue = sinon.stub().callsFake(async (queue, msg) => {
  const cb = spies.channel.queues[queue] || (async () => {})
  await cb({ content: JSON.parse(msg.toString()) })
})

spies.channel.consume = sinon.stub().callsFake(async (queue, callback) => {
  spies.channel.queues[queue] = callback
  return { consumerTag: queue }
})

spies.channel.reject = sinon.stub()
spies.channel.ack = sinon.stub()
spies.channel.close = sinon.stub().callsFake(async () => {})
spies.channel.cancel = sinon.stub().callsFake(async queue => {
  delete spies.channel.queues[queue]
})

mock('amqplib', spies.amqplib)
