const sinon = require('sinon')
const spies = require(`${process.cwd()}/tests/mocks.js`)

function stub_console_log() {
  const records = []

  this.stubs = {}
  this.stubs.console_log = sinon.stub(console, 'log').callsFake(
    (...args) => {
      records.push(
        Object.fromEntries(
          args
            .join(' ')
            .split(' ')
            .map(kv => kv.split('='))
        )
      )
    }
  )

  this.records = records
}

function reset_stub_console_log() {
  this.stubs.console_log.restore()
}

function reset_spies() {
  spies.dockerode.resetHistory()
}

module.exports = {
  before: function() {
    stub_console_log.apply(this)
  },
  after: function() {
    reset_stub_console_log.apply(this)
    reset_spies.apply(this)
  }
}
