const { make_kubectl } = require('./kube.js')

const dummy = async () => ({})

class AsyncEvent {
  constructor () {
    this.flag = false
  }

  clear () {
    this.flag = false
  }

  set () {
    this.flag = true
  }

  is_set () {
    return this.flag
  }

  async wait (interval = 10) {
    while (!this.is_set()) {
      await new Promise(resolve => setTimeout(resolve, interval))
    }

    throw this
  }
}

const make_operator = async ({ lifecycle = {}, watches = [] }) => {
  const initialize = lifecycle.initialize || dummy
  const terminate = lifecycle.terminate || dummy

  const kubectl = await make_kubectl()
  const context = await initialize()
  const stop_event = new AsyncEvent()
  const streams = []

  const stop_event_watcher = stop_event.wait()
  const watchers = watches.map(async ({ apiVersion, kind, namespace, name, on }) => {
    const stream = await kubectl.watch({ apiVersion, kind, namespace, name })
    stream.on('data', async ({ type, object }) => {
      const handler = on[type] || dummy
      await handler(kubectl, context, object)
    })
    streams.push(stream)
  })

  return {
    kubectl,
    cancel: () => {
      stop_event.set()
    },
    join: async () => {
      try {
        await Promise.all([
          stop_event_watcher,
          ...watchers
        ])
      }
      catch (err) {
        if (!(err instanceof AsyncEvent)) {
          throw err
        }
      }
      finally {
        streams.map(stream => stream.destroy())
        await terminate(kubectl, context)
      }
    }
  }
}

const adopt_resource = (owner, resource) => {
  resource.metadata = resource.metadata || {}
  resource.metadata.ownerReferences = resource.metadata.ownerReferences || []
  resource.metadata.ownerReferences.push({
    apiVersion: owner.apiVersion,
    kind: owner.kind,
    name: owner.metadata.name,
    uid: owner.metadata.uid,
    blockOwnerDeletion: true
  })
  return resource
}

module.exports = { make_operator, adopt_resource }
