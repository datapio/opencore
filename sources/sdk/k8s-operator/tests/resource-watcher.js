const { withWorld } = require('test!world')
const { it } = require('mocha')

const { KubeInterface } = require('../src/index')
const { ResourceWatcher } = require('../src/index')
const { expect } = require('chai')

class TestWatcher extends ResourceWatcher {
  constructor(kubectl) {
    super(kubectl, {
      apiVersion: 'example.com/v1',
      kind: 'Example',
      namespace: 'default'
    })
  }

  async added(object) {
    await super.added(object)  // for code coverage

    withWorld(world => {
      world.watcher.added = true
    })
  }

  async modified(object) {
    await super.modified(object)  // for code coverage

    withWorld(world => {
      world.watcher.modified = true
    })
  }

  async removed(object) {
    await super.removed(object)  // for code coverage

    withWorld(world => {
      world.watcher.removed = true
    })
  }
}

module.exports = () => {
  it('should watch a resource', async () => {
    const kubectl = new KubeInterface()
    await kubectl.load()

    const watcher = new TestWatcher(kubectl)

    const cancelScope = await watcher.watch()

    withWorld(world => {
      world.stream.push({ type: 'added', object: {} })
      world.stream.push({ type: 'modified', object: {} })
      world.stream.push({ type: 'removed', object: {} })
    })

    await 0 // breakpoint to let the promise execute
    cancelScope.cancel()

    withWorld(world => {
      expect(world.watcher.added).to.be.true
      expect(world.watcher.modified).to.be.true
      expect(world.watcher.removed).to.be.true
    })
  })
}
