const Request = require('kubernetes-client/backends/request')
const kubernetes = require('kubernetes-client')


class KubeError extends Error {
  constructor(msg, details = null) {
    super(msg)
    this.name = this.constructor.name
    this.details = details
    Error.captureStackTrace(this, this.constructor)
  }
}

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
      ep = client.apis[apiGroup][resourceVersion]
    }
    else {
      ep = client.api[resourceVersion]
    }

    if (watch) {
      ep = ep.watch
    }

    if (namespace) {
      ep = ep.namespaces(namespace)
    }

    ep = ep[kind.toLowerCase()]

    if (name) {
      ep = ep(name)
    }
  }
  catch (err) {
    throw new KubeError(
      'Unknown API',
      {
        meta,
        err
      }
    )
  }

  return ep
}

const response = {
  assertStatusCode: resp => {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw new KubeError(
        'Unexpected response from Kubernetes API Server',
        {
          resp
        }
      )
    }
  },
  unwrap: (resp, many = false) => {
    response.assertStatusCode(resp)
    return many ? resp.body.items : resp.body
  }
}

class KubeInterface {
  constructor({ crds = [], createCRDs = true, config = null }) {
    if (config !== null) {
      this.config = config
    }
    else {
      this.config = new kubernetes.KubeConfig()
      this.config.loadFromDefault()
    }

    this.backend = new Request({ kubeconfig: this.config })
    this.client = new kubernetes.Client({ backend: this.backend })
    this.crds = crds
    this.createCRDs = createCRDs
  }

  async load() {
    await this.client.loadSpec()

    await Promise.all(this.crds.map(async crd => {
      if (this.createCRDs) {
        const api = this.client.apis['apiextensions.k8s.io'].v1beta1.customresourcedefinitions // eslint-disable-line max-len

        try {
          await api(crd.metadata.name).get()
        }
        catch (err) {
          await api.post({ body: crd })
        }
      }

      this.client.addCustomResourceDefinition(crd)
    }))
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
        'content-type': 'application/merge-patch+json'
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

KubeInterface.Error = KubeError

module.exports = KubeInterface
