const CancelScope = require('./cancel-scope')

class ResourceWatcher {
  constructor({ apiVersion, kind, namespace, name }) {
    this.meta = {
      apiVersion,
      kind,
      namespace,
      name
    }
  }

  async watch(operator) {
    const stream = await operator.kubectl.watch(this.meta)
    const handlers = {
      added: this.added.bind(this),
      modified: this.modified.bind(this),
      deleted: this.deleted.bind(this)
    }

    stream.on('data', async ({ type, object }) => {
      const handler = handlers[type]
      await handler(operator, object)
    })

    return new CancelScope(() => stream.end())
  }

  async added(operator, object) {} // eslint-disable-line no-unused-vars

  async modified(operator, object) {} // eslint-disable-line no-unused-vars

  async deleted(operator, object) {} // eslint-disable-line no-unused-vars
}

module.exports = ResourceWatcher
