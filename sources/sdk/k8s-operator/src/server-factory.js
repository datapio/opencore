/**
 * HTTP(S) server(s) factory.
 * @module server-factory
 */

const mergeOptions = require('merge-options').bind({ ignoreUndefined: true })
const https = require('https')
const http = require('http')
const fs = require('fs')

/**
 * Creates HTTP(S) server(s)
 * @class ServerFactory
 */
class ServerFactory {
  /**
   * @typedef ServerFactoryConfiguration
   * @property {HTTPSConfiguration} https
   * @property {HTTPConfiguration} http
   */

  /**
   * @typedef HTTPSConfiguration
   * @property {Boolean} enabled Activate HTTPS support
   * @property {Number} port HTTPS port to listen
   * @property {String} key Path to X.509 Server Certificate private key
   * @property {String} cert Path to X.509 Server Certificate public key
   * @property {String} ca Path to X.509 Certificate Authority that signed the Server Certificate
   */

  /**
   * @typedef HTTPConfiguration
   * @property port HTTP port to listen
   */

  defaultOptions = {
    https: {
      enabled: false,
      port: 8443,
      key: '/path/to/key.pem',
      cert: '/path/to/cert.pem',
      ca: '/path/to/ca.pem'
    },
    http: {
      port: 8000
    }
  }

  /**
   * Create a new Server Factory
   * @param {ServerFactoryOptions} options
   */
  constructor(options = {}) {
    this.options = mergeOptions(this.defaultOptions, options)
  }

  /**
   * @typedef {(http.Server|https.Server)} HTTPServer
   */

  /**
   * Create the HTTP(S) server(s)
   *
   * @param {Object} api `createServer` options
   * @returns {Array<HTTPServer>} HTTP(S) server(s)
   */
  make(api) {
    const servers = [
      {
        server: http.createServer(api),
        port: this.options.http.port
      }
    ]

    if (this.options.https.enabled) {
      servers.push({
        server: https.createServer(
          {
            key: fs.readFileSync(this.options.https.key),
            cert: fs.readFileSync(this.options.https.cert),
            ca: fs.readFileSync(this.options.https.ca)
          },
          api
        ),
        port: this.options.https.port
      })
    }

    return servers
  }
}

module.exports = ServerFactory
