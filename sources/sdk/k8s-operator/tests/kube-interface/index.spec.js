const { describe, it } = require('mocha')
const { setUp } = require('test!world')
const sinon = require('sinon')

const { KubeInterface } = require('../../src/index')

describe('KubeInterface', () => {
  beforeEach(setUp)

  it('should create a client a load the server API specification', async () => {
    const kubectl = new KubeInterface({ crds: [
      {
        metadata: {
          name: 'crd-foo'
        }
      }
    ]})
    await kubectl.load()

    sinon.assert.calledOnce(kubectl.client.loadSpec)

    sinon.assert.calledWith(
      kubectl.client.addCustomResourceDefinition,
      { metadata: { name: 'crd1' }}
    )
    sinon.assert.calledWith(
      kubectl.client.addCustomResourceDefinition,
      { metadata: { name: 'crd2' }}
    )
    sinon.assert.calledWith(
      kubectl.client.addCustomResourceDefinition,
      { metadata: { name: 'crd-foo' }}
    )
  })

  describe('create', require('./create'))
  describe('list', require('./list'))
  describe('get', require('./get'))
  describe('watch', require('./watch'))
  describe('patch', require('./patch'))
  describe('delete', require('./delete'))
  describe('logs', require('./logs'))
  describe('exec', require('./exec'))
})
