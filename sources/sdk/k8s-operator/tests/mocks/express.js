const sinon = require('sinon')

const app = () => 'default backend'
app.use = sinon.stub()

module.exports = () => app
