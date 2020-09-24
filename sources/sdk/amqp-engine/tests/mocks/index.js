const mock = require('mock-require')

mock('amqplib', require('./amqp'))
