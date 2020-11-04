const kubernetes = require('kubernetes-client')
const sinon = require('sinon')

const config = new kubernetes.KubeConfig()
config.addCluster({
  name: 'test-cluster',
  server: 'http://test-server'
})
config.addUser({
  name: 'test-user',
  token: 'test-token'
})
config.addContext({
  cluster: 'test-cluster',
  name: 'test-context',
  user: 'test-user',
  namespace: 'default'
})
config.setCurrentContext('test-context')

module.exports = {
  load: sinon.stub().resolves(),
  config
}