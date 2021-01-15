const sinon = require('sinon')

const app = () => 'default backend'
app.use = sinon.stub()
app.get = sinon.stub()

module.exports = () => app
