const { createTerminus } = require('@godaddy/terminus')

class WebService {
  constructor(operator, serverFactory) {
    this.operator = operator
    this.servers = serverFactory.make(this.operator.webapp)
    this.cancelScopes = []

    this.servers.map(server => createTerminus(server, {
      healthChecks: {
        '/health': this.operator.healthCheck.bind(this.operator),
        '/metrics': this.operator.metrics.bind(this.operator),
        verbatim: true
      },
      beforeShutdown: this.beforeShutdown.bind(this),
      onSignal: this.shutdownRequested.bind(this),
      onShutdown: this.shutdownDone.bind(this),
      onSendFailureDuringShutdown: this.shutdownFailed.bind(this),
      logger: this.logger.bind(this)
    }))
  }

  async beforeListen() {
    await this.operator.kubectl.load()
    await this.operator.initialize()

    this.cancelScopes = await Promise.all(
      this.operator.watchers.map(watcher => watcher.watch(this.operator))
    )
  }

  async beforeShutdown() {
    this.cancelScopes.map(cancelScope => cancelScope.cancel())
  }

  async shutdownRequested() {
    console.log('Shutdown requested')
  }

  async shutdownDone() {
    await this.operator.terminate()
  }

  async shutdownFailed(err) {
    console.error(err)
  }

  async logger(msg, payload) {
    console.log(msg, payload)
  }

  async listen() {
    await this.beforeListen()

    return await Promise.all(
      this.servers.map(({ server, port }) =>
        new Promise((resolve, reject) => {
          server.listen(port)
            .once('listening', resolve)
            .once('error', reject)
        })
      )
    )
  }
}

module.exports = WebService
