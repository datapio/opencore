
const sinon = require('sinon')

const amqplib = sinon.spy()
const conn = sinon.spy()
const channel = sinon.spy()

amqplib.connect = sinon.stub().resolves(conn)
conn.createChannel = sinon.stub().resolves(channel)
conn.close = sinon.stub().resolves()

channel.assertExchange = sinon.stub().resolves()
channel.assertQueue = sinon.stub().resolves()
channel.bindQueue = sinon.stub().resolves()
channel.ack = sinon.stub().resolves()
channel.nack = sinon.stub().resolves()
channel.sendToQueue = sinon.stub().resolves()
channel.publish = sinon.stub().resolves()
channel.consume = sinon.stub().resolves({ consumerTag: 'tag' })
channel.cancel = sinon.stub().resolves()
channel.close = sinon.stub().resolves()

amqplib.testEnv = {
  conn,
  channel
}

module.exports = amqplib
