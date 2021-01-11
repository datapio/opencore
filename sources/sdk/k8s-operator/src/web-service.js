/**
 * Handle Kubernetes Pod's lifecycle.
 * @module web-service
 */

const { createTerminus } = require('@godaddy/terminus')

/**
 * Operator Web Service LifeCycle manager
 * @class WebService
 */
class WebService {
  /**
   * Create a new WebService
   * @param {Operator} operator Operator owning the web service
   * @param {ServerFactory} serverFactory HTTP(S) server factory
   */
  constructor(operator, serverFactory) {
    this.operator = operator
    this.servers = serverFactory.make(this.operator.webapp)
    this.cancelScopes = []

    this.servers.map(({ server }) => createTerminus(server, {
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

  /**
   * Callback called before openning the HTTP(S) port(s).
   * @returns {Promise<void>}
   */
  async beforeListen() {
    await this.operator.kubectl.load()
    await this.operator.initialize()

    this.cancelScopes = await Promise.all(
      this.operator.watchers.map(watcher => watcher.watch(this.operator))
    )
  }

  /**
   * Callback called before shutdown triggered by Kubernetes Pod's restart
   * @returns {Promise<void>}
   */
  async beforeShutdown() {
    this.cancelScopes.map(cancelScope => cancelScope.cancel())
  }

  /**
   * Callback called when a shutdown was triggered by the Kubernetes Pod
   * @returns {Promise<void>}
   */

  async shutdownRequested() {
    console.log('Shutdown requested')
  }

  /**
   * Callback called after HTTP(S) server(s) shutdown
   * @returns {Promise<void>}
   */
  async shutdownDone() {
    await this.operator.terminate()
  }

  /**
   * Callback called when the HTTP(S) server(s) shutdown failed
   *
   * @param {Error} err Error thrown during shutdown
   * @returns {Promise<void>}
   */
  async shutdownFailed(err) {
    console.error(err)
  }

  /**
   * Callback called when the terminus library wants to log information.
   *
   * @param {any} msg
   * @param {any} payload
   * @returns {Promise<void>}
   */
  async logger(msg, payload) {
    console.log(msg, payload)
  }

  /**
   * Open HTTP(S) port(s).
   * @returns {Promise<void>} Resolves once all ports are open
   */
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
