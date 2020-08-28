const kubernetes = require('kubernetes-client')

const dummy = async () => ({ condition: true, res: null })

const parse_api_version = api_version =>
  ((/^(?:(?<apiGroup>[a-zA-Z][a-zA-Z0-9\-_.]*)\/)?(?<resourceVersion>.*)$/u).exec(api_version) || {}).groups

const get_endpoint = (client, { apiGroup, resourceVersion, kind, namespace, name }, watch = false) => {
  let ep = null

  if (apiGroup) {
    ep = client.apis[apiGroup][resourceVersion][kind.toLowerCase()]
  }
  else {
    ep = client.api[resourceVersion][kind.toLowerCase()]
  }

  if (watch) {
    ep = ep.watch
  }

  if (namespace) {
    ep = ep.namespaces(namespace)
  }

  if (name) {
    ep = ep(name)
  }

  return ep
}

const valid_statuscode = code => code >= 200 && code < 300

const unwrap_resp = (resp, many = false) => {
  if (!valid_statuscode(resp.statusCode)) {
    throw new Error(
      `Unexpected response from Kubernetes API Server: ${resp.statusCode} - ${JSON.stringify(resp.body)}`
    )
  }
  else {
    return many ? resp.body.items : resp.body
  }
}

const make_kubectl = async () => {
  const client = new kubernetes.Client()
  await client.loadSpec()

  const kubectl = {
    client,
    create: async (...resources) => {
      return await Promise.all(resources
        .map(resource => ({
          kind: resource.kind,
          namespace: resource.metadata.namespace,
          body: resource,
          ...parse_api_version(resource.apiVersion)
        }))
        .map(({ apiGroup, resourceVersion, kind, namespace, body }) => ({
          endpoint: get_endpoint(client, { apiGroup, resourceVersion, kind, namespace }),
          body
        }))
        .map(async ({ endpoint, body }) => {
          return await endpoint.post({ body })
        })
        .map(async resp => unwrap_resp(await resp))
      )
    },
    list: async ({ apiVersion, kind, namespace, labels }) => {
      const { apiGroup, resourceVersion } = parse_api_version(apiVersion)
      const endpoint = get_endpoint(client, { apiGroup, resourceVersion, kind, namespace })
      return unwrap_resp(
        await endpoint.get({ qs: `l=${encodeURIComponent(labels)}` }),
        true
      )
    },
    get: async ({ apiVersion, kind, namespace, name }) => {
      const { apiGroup, resourceVersion } = parse_api_version(apiVersion)
      const endpoint = get_endpoint(client, { apiGroup, resourceVersion, kind, namespace, name })
      return unwrap_resp(await endpoint.get())

    },
    watch: async ({ apiVersion, kind, namespace, name }) => {
      const { apiGroup, resourceVersion } = parse_api_version(apiVersion)
      const endpoint = get_endpoint(client, { apiGroup, resourceVersion, kind, namespace, name }, true)
      return endpoint.getObjectStream()
    },
    wait_condition: async ({ apiVersion, kind, namespace, name, callback = dummy }) => {
      const rsrc_stream = await kubectl.watch({ apiVersion, kind, namespace, name })
      const result = await new Promise((resolve, reject) => {
        rsrc_stream.on('data', async ({ object }) => {
          try {
            const { condition, res } = await callback(object)
            if (condition) {
              resolve(res)
            }
          }
          catch (err) {
            reject(err)
          }
        })
      })

      rsrc_stream.destroy()
      return result
    },
    patch: async ({ apiVersion, kind, namespace, name, patch }) => {
      const { apiGroup, resourceVersion } = parse_api_version(apiVersion)
      const endpoint = get_endpoint(client, { apiGroup, resourceVersion, kind, namespace, name })
      return unwrap_resp(await endpoint.patch({
        body: patch,
        headers: {
          content_type: 'application/merge-patch+json'
        }
      }))
    },
    delete: async ({ apiVersion, kind, namespace, name }) => {
      const { apiGroup, resourceVersion } = parse_api_version(apiVersion)
      const endpoint = get_endpoint(client, { apiGroup, resourceVersion, kind, namespace, name })
      return unwrap_resp(await endpoint.delete())
    }
  }

  return kubectl
}

module.exports = { make_kubectl }
