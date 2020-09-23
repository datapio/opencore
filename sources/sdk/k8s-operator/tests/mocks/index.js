const mock = require('mock-require')

mock('test!world', require('./test-world'))
mock('http', require('./http'))
mock('https', require('./https'))
mock('fs', require('./fs'))
mock('@godaddy/terminus', require('./terminus'))
mock('kubernetes-client', require('./kubernetes-client'))
