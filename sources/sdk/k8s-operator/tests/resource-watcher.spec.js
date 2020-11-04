const { setUp, withWorld } = require('test!world')
const { describe, it } = require('mocha')

const { KubeInterface } = require('../src/index')
const { ResourceWatcher } = require('../src/index')
const { expect } = require('chai')

class TestWatcher extends ResourceWatcher {
  constructor() {
    super({
      apiVersion: 'example.com/v1',
      kind: 'Example',
      namespace: 'default'
    })
  }

  async added(operator, object) {
    await super.added(operator, object)  // for code coverage

    withWorld(world => {
      world.watcher.added = true
    })
  }

  async modified(operator, object) {
    await super.modified(operator, object)  // for code coverage

    withWorld(world => {
      world.watcher.modified = true
    })
  }

  async deleted(operator, object) {
    await super.deleted(operator, object)  // for code coverage

    withWorld(world => {
      world.watcher.deleted = true
    })
  }
}

describe('ResourceWatcher', () => {
  beforeEach(setUp)

  it('should watch a resource being added', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const watcher = new TestWatcher()

    const cancelScope = await watcher.watch({ kubectl })

    withWorld(world => {
      world.stream.push({ type: 'added', object: {} })
    })

    await 0 // breakpoint to let the promise execute
    cancelScope.cancel()

    withWorld(world => {
      expect(world.watcher.added).to.be.true
    })
  })

  it('should watch a resource being modified', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const watcher = new TestWatcher()

    const cancelScope = await watcher.watch({ kubectl })

    withWorld(world => {
      world.stream.push({ type: 'modified', object: {} })
    })

    await 0 // breakpoint to let the promise execute
    cancelScope.cancel()

    withWorld(world => {
      expect(world.watcher.modified).to.be.true
    })
  })

  it('should watch a resource being deleted', async () => {
    const kubectl = new KubeInterface({})
    await kubectl.load()

    const watcher = new TestWatcher()

    const cancelScope = await watcher.watch({ kubectl })

    withWorld(world => {
      world.stream.push({ type: 'deleted', object: {} })
    })

    await 0 // breakpoint to let the promise execute
    cancelScope.cancel()

    withWorld(world => {
      expect(world.watcher.deleted).to.be.true
    })
  })
})
