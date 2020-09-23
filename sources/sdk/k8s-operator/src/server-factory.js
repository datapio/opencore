const mergeOptions = require('merge-options').bind({ignoreUndefined: true});
const https = require('https')
const http = require('http')
const fs = require('fs')

class ServerFactory {
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

  constructor(options = {}) {
    this.options = mergeOptions(this.defaultOptions, options)
  }

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
