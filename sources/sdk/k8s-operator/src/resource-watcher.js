const CancelScope = require('./cancel-scope')

class ResourceWatcher {
  constructor(kubectl, { apiVersion, kind, namespace, name }) {
    this.kubectl = kubectl
    this.meta = {
      apiVersion,
      kind,
      namespace,
      name
    }
  }

  async watch() {
    const stream = await this.kubectl.watch(this.meta)
    const handlers = {
        added: this.added.bind(this),
        modified: this.modified.bind(this),
        removed: this.removed.bind(this)
    }

    stream.on('data', async ({ type, object }) => {
      const handler = handlers[type]
      await handler(object)
    })

    return new CancelScope(() => stream.end())
  }

  async added(object) {}
  async modified(object) {}
  async removed(object) {}
}

module.exports = ResourceWatcher
