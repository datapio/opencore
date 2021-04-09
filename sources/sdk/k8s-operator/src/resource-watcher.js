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
    const context = {
      stream: await operator.kubectl.watch(this.meta),
      restart: true
    }
    const handlers = {
      added: this.added.bind(this),
      modified: this.modified.bind(this),
      deleted: this.deleted.bind(this)
    }

    const callHandler = async ({ type, object }) => {
      const handler = handlers[type.toLowerCase()]
      await handler(operator, object)
    }
    const restartHandler = async () => {
      if (context.restart) {
        context.stream = await operator.kubectl.watch(this.meta)
        context.stream.on('data', callHandler)
        context.stream.on('end', restartHandler)
      }
    }

    context.stream.on('data', callHandler)
    context.stream.on('end', restartHandler)

    return new CancelScope(() => {
      context.restart = false
      context.stream.end()
    })
  }

  async added(operator, object) {} // eslint-disable-line no-unused-vars

  async modified(operator, object) {} // eslint-disable-line no-unused-vars

  async deleted(operator, object) {} // eslint-disable-line no-unused-vars
}

module.exports = ResourceWatcher
