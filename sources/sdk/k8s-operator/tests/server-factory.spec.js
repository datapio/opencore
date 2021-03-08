const { describe, it } = require('mocha')
const { setUp } = require('test!world')
const { expect } = require('chai')
const sinon = require('sinon')

const { ServerFactory } = require('../src/index')

const https = require('https')
const http = require('http')
const fs = require('fs')

describe('ServerFactory', () => {
  beforeEach(setUp)

  it('should use default options when none are provided', () => {
    const serverFactory = new ServerFactory()
    expect(serverFactory.options).to.deep.equal(serverFactory.defaultOptions)
  })

  it('should override default options when custom options are provided', () => {
    const serverFactory = new ServerFactory({ https: { enabled: true } })
    expect(serverFactory.options).to.deep.equal({
      https: {
        enabled: true,
        port: 8443,
        key: '/path/to/key.pem',
        cert: '/path/to/cert.pem',
        ca: '/path/to/ca.pem'
      },
      http: {
        enabled: true,
        port: 8000
      }
    })
  })

  it('should create only an HTTP server when HTTPS is enabled', () => {
    const serverFactory = new ServerFactory()
    const api = sinon.spy()

    const servers = serverFactory.make(api)

    expect(servers).to.be.an('array').of.length(1)
    expect(servers[0]).to.be.an('object')
    expect(servers[0].port).to.equal(8000)

    sinon.assert.calledWith(http.createServer, api)
  })

  it('should create an HTTP and an HTTPS server when HTTPS is enabled', () => {
    const serverFactory = new ServerFactory({ https: { enabled: true }})
    const api = sinon.spy()

    const servers = serverFactory.make(api)

    expect(servers).to.be.an('array').of.length(2)
    expect(servers[0]).to.be.an('object')
    expect(servers[0].port).to.equal(8000)

    expect(servers[1]).to.be.an('object')
    expect(servers[1].port).to.equal(8443)

    sinon.assert.calledWith(http.createServer, api)
    sinon.assert.calledWith(https.createServer, {
      key: 'DATA',
      cert: 'DATA',
      ca: 'DATA'
    }, api)
    sinon.assert.calledWith(fs.readFileSync, '/path/to/key.pem')
    sinon.assert.calledWith(fs.readFileSync, '/path/to/cert.pem')
    sinon.assert.calledWith(fs.readFileSync, '/path/to/ca.pem')
  })

  it('should create an HTTPS server when HTTPS is enabled but HTTP is disabled', () => {
    const serverFactory = new ServerFactory({
      https: { enabled: true },
      http: { enabled: false }
    })
    const api = sinon.spy()
    const servers = serverFactory.make(api)

    expect(servers).to.be.an('array').of.length(1)
    expect(servers[0]).to.be.an('object')
    expect(servers[0].port).to.equal(8443)

    sinon.assert.calledWith(https.createServer, {
      key: 'DATA',
      cert: 'DATA',
      ca: 'DATA'
    }, api)
    sinon.assert.calledWith(fs.readFileSync, '/path/to/key.pem')
    sinon.assert.calledWith(fs.readFileSync, '/path/to/cert.pem')
    sinon.assert.calledWith(fs.readFileSync, '/path/to/ca.pem')
  })

  it('should throw an error when both HTTP and HTTPS are disabled', () => {
    const serverFactory = new ServerFactory({
      https: { enabled: false },
      http: { enabled: false }
    })
    const api = sinon.spy()

    try {
      serverFactory.make(api)
      throw new Error('no error thrown')
    }
    catch (err) {
      expect(err.name).to.equal('OperatorError')
    }
  })
})
