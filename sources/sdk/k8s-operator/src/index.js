const { make_kubectl } = require('./kube.js')

const dummy = async () => ({})

const operator = async ({ lifecycle: { initialize = dummy, terminate = dummy }, watches }) => {
  const kubectl = await make_kubectl()
  const context = await initialize(kubectl)
  const streams = []

  try {
    await Promise.all(
      watches.map(async ({ apiVersion, kind, namespace, on }) => {
        const stream = await kubectl.watch({ apiVersion, kind, namespace, name })
        stream.on('data', async ({ type, object }) => {
          const handler = on[type] || dummy
          await handler(kubectl, context, object)
        })
        streams.push(stream)
      })
    )
  }
  finally {
    streams.map(stream => stream.destroy())
    await terminate(kubectl, context)
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

module.exports = { operator, adopt_resource }
