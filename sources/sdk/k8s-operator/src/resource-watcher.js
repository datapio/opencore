/**
 * Kubernetes resource monitoring.
 * @module resource-watcher
 */

const CancelScope = require('./cancel-scope')

/**
 * Watch Kubernetes resources
 *
 * @class ResourceWatcher
 */
class ResourceWatcher {
  /**
   * @typedef ResourceWatcherConfiguration
   * @property {String} apiVersion Kubernetes resource API version
   * @property {String} kind Kubernetes resource kind
   * @property {String} [namespace] Kubernetes resource namespace
   * @property {String} [name] Kubernetes resource name
   */

  /**
   * Create a new resource watcher
   * @param {ResourceWatcherConfiguration} params
   */
  constructor({ apiVersion, kind, namespace, name }) {
    this.meta = {
      apiVersion,
      kind,
      namespace,
      name
    }
  }

  /**
   * Watch Kubernetes events.
   * NB: This method is scoped to the operator
   *
   * @param {Operator} operator Operator owning the watcher
   * @returns {Promise<CancelScope>}
   */
  async watch(operator) {
    const stream = await operator.kubectl.watch(this.meta)
    const handlers = {
      added: this.added.bind(this),
      modified: this.modified.bind(this),
      deleted: this.deleted.bind(this)
    }

    stream.on('data', async ({ type, object }) => {
      const handler = handlers[type.toLowerCase()]
      await handler(operator, object)
    })

    return new CancelScope(() => stream.end())
  }

  /**
   * Callback handling newly created resources.
   * NB: should be overriden
   *
   * @param {Operator} operator Operator owning the watcher
   * @param {Object} object Newly created Kubernetes resource
   */
  async added(operator, object) {} // eslint-disable-line no-unused-vars

  /**
   * Callback handling recently modified resources.
   * NB: should be overriden
   *
   * @param {Operator} operator Operator owning the watcher
   * @param {Object} object Recently modified Kubernetes resource
   */
  async modified(operator, object) {} // eslint-disable-line no-unused-vars

  /**
   * Callback handling recently deleted resources.
   * NB: should be overriden
   *
   * @param {Operator} operator Operator owning the watcher
   * @param {Object} object Recently deleted Kubernetes resource
   */
  async deleted(operator, object) {} // eslint-disable-line no-unused-vars
}

module.exports = ResourceWatcher
