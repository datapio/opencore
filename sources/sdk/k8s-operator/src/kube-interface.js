const kubernetes = require('kubernetes-client')

const defaultCallback = async () => ({ condition: true, res: null })

const parseApiVersion = apiVersion =>
  // eslint-disable-next-line max-len
  (/^(?:(?<apiGroup>[a-zA-Z][a-zA-Z0-9\-_.]*)\/)?(?<resourceVersion>.*)$/u).exec(apiVersion).groups

const getEndpoint = (client, meta, watch = false) => {
  const {
    apiGroup,
    resourceVersion,
    kind,
    namespace,
    name
  } = meta

  let ep = null

  try {
    if (apiGroup) {
      ep = client.apis[apiGroup][resourceVersion][kind.toLowerCase()]
    }
    else {
      ep = client.api[resourceVersion][kind.toLowerCase()]
    }

    if (!ep) {
      throw new Error('unkown kind')
    }
  }
  catch (err) {
    throw new Error(`Unknown API: ${apiGroup}/${resourceVersion} ${kind}`)
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

const response = {
  assertStatusCode: resp => {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw new Error(
        `Unexpected response from Kubernetes API Server: ${
          resp.statusCode
        } - ${
          JSON.stringify(resp.body)
        }`
      )
    }
  },
  unwrap: (resp, many = false) => {
    response.assertStatusCode(resp)
    return many ? resp.body.items : resp.body
  }
}

class KubeInterface {
  constructor() {
    this.client = new kubernetes.Client()
  }

  async load() {
    await this.client.loadSpec()
  }

  async create(...resources) {
    return await Promise.all(resources
      .map(resource => ({
        kind: resource.kind,
        namespace: resource.metadata.namespace,
        body: resource,
        ...parseApiVersion(resource.apiVersion)
      }))
      .map(({ apiGroup, resourceVersion, kind, namespace, body }) => ({
        endpoint: getEndpoint(this.client, {
          apiGroup,
          resourceVersion,
          kind,
          namespace
        }),
        body
      }))
      .map(async ({ endpoint, body }) => {
        return await endpoint.post({ body })
      })
      .map(async resp => response.unwrap(await resp))
    )
  }

  async list({ apiVersion, kind, namespace, labels }) {
    const { apiGroup, resourceVersion } = parseApiVersion(apiVersion)
    const endpoint = getEndpoint(this.client, {
      apiGroup,
      resourceVersion,
      kind,
      namespace
    })

    return response.unwrap(
      await endpoint.get({ qs: `l=${encodeURIComponent(labels)}` }),
      true
    )
  }

  async get({ apiVersion, kind, namespace, name }) {
    const { apiGroup, resourceVersion } = parseApiVersion(apiVersion)
    const endpoint = getEndpoint(this.client, {
      apiGroup,
      resourceVersion,
      kind,
      namespace,
      name
    })

    return response.unwrap(await endpoint.get())
  }

  async watch({ apiVersion, kind, namespace, name }) {
    const { apiGroup, resourceVersion } = parseApiVersion(apiVersion)
    const endpoint = getEndpoint(this.client, {
      apiGroup,
      resourceVersion,
      kind,
      namespace,
      name
    }, true)

    return endpoint.getObjectStream()
  }

  async waitCondition({
    apiVersion,
    kind,
    namespace,
    name,
    callback = defaultCallback
  }) {
    const resourceStream = await this.watch({
      apiVersion,
      kind,
      namespace,
      name
    })

    const result = await new Promise((resolve, reject) => {
      resourceStream.on('data', async ({ object }) => {
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

    resourceStream.destroy()
    return result
  }

  async patch({ apiVersion, kind, namespace, name, patch }) {
    const { apiGroup, resourceVersion } = parseApiVersion(apiVersion)
    const endpoint = getEndpoint(this.client, {
      apiGroup,
      resourceVersion,
      kind,
      namespace,
      name
    })

    return response.unwrap(await endpoint.patch({
      body: patch,
      headers: {
        content_type: 'application/merge-patch+json'
      }
    }))
  }

  async delete({ apiVersion, kind, namespace, name }) {
    const { apiGroup, resourceVersion } = parseApiVersion(apiVersion)
    const endpoint = getEndpoint(this.client, {
      apiGroup,
      resourceVersion,
      kind,
      namespace,
      name
    })

    return response.unwrap(await endpoint.delete())
  }
}

module.exports = KubeInterface
