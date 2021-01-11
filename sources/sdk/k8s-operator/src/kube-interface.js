/**
 * Wrapper for Kubernetes API Server client.
 * @module kube-interface
 */

const Request = require('kubernetes-client/backends/request')
const kubernetes = require('kubernetes-client')

/**
 * Domain specific error.
 * @class KubeError
 */
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

  const fns = [
    () => {
      return apiGroup
        ? client.apis[apiGroup][resourceVersion]
        : client.api[resourceVersion]
    },
    ep => {
      return watch ? ep.watch : ep
    },
    ep => {
      return namespace ? ep.namespaces(namespace) : ep
    },
    ep => {
      return ep[kind.toLowerCase()]
    },
    ep => {
      return name ? ep(name) : ep
    }
  ]

  try {
    return fns.reduce(
      (ep, fn) => fn(ep),
      null
    )
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

/**
 * Wrapper object for Kubernetes API Server client
 * @class KubeInterface
 */
class KubeInterface {
  /**
   * @typedef {Object} KubeInterfaceConfiguration
   * @property {Array} crds List of Custom Resource Definitions to add
   * @property {Boolean} createCRDS Create CRDs unknown by the server if enabled
   * @property {Object} [config] KubeConfig to use (or `null`)
   */

  /**
   * Create a new Kubernetes client
   * @param {KubeInterfaceConfiguration} params
   */
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

  /**
   * Load the API definition from the server.
   *
   * @returns {Promise<void>}
   *
   * This is located either at /openapi/v2 or /swagger.json
   *
   * NB: if the `createCRDs` flag is set, every CRDs from the `crds` array
   *     unknown to the server will be created.
   */
  async load() {
    await this.client.loadSpec()

    const extension = this.client.apis['apiextensions.k8s.io'].v1beta1
    const api = extension.customresourcedefinitions

    const remoteCRDs = response.unwrap(await api.get(), true)
    const missingCRDs = this.crds.filter(
      crd => remoteCRDs.filter(
        remoteCRD => crd.metadata.name === remoteCRD.metadata.name
      ).length === 0
    )

    if (this.createCRDs) {
      await Promise.all(missingCRDs.map(async crd => {
        await api.post({ body: crd })
      }))
    }

    this.crds = [
      ...remoteCRDs,
      ...missingCRDs
    ]

    this.crds.map(this.client.addCustomResourceDefinition.bind(this.client))
  }

  /**
   * Create resources.
   *
   * NB: Resources are created in parallel.
   *
   * @param  {...Object} resources Resource to create
   * @returns {Promise<Array<Object>>} Resolve to the list of created ressources or reject with the first thrown error
   */
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

  /**
   * @typedef {Object} ListRequestInfo
   * @property {String} apiVersion Kubernetes resource API version
   * @property {String} kind Kubernetes resource kind
   * @property {String} [namespace] Kubernetes resource namespace
   * @property {String} [labels] Kubernetes resource label filter
   */

  /**
   * List resources matching the supplied parameters.
   *
   * @param {ListRequestInfo} params
   * @returns {Promise<Array<Object>>} Matching Kubernetes resources
   */
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

  /**
   * @typedef {Object} GetRequestInfo
   * @property {String} apiVersion Kubernetes resource API version
   * @property {String} kind Kubernetes resource kind
   * @property {String} [namespace] Kubernetes resource namespace
   * @property {String} name Kubernetes resource name
   */

  /**
   * Get a single resource by name.
   *
   * @param {GetRequestInfo} params
   * @returns {Promise<Object>} Matching Kubernetes resource
   */
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

  /**
   * @typedef {Object} WatchRequestInfo
   * @property {String} apiVersion Kubernetes resource API version
   * @property {String} kind Kubernetes resource kind
   * @property {String} [namespace] Kubernetes resource namespace
   * @property {String} [name] Kubernetes resource name
   */

  /**
   * Watch Kubernetes resources.
   * A stream object will be returned, and Kubernetes events will be received on the 'data' stream event
   *
   * @param {WatchRequestInfo} params
   * @returns {Promise<stream.Readable>}
   */
  async watch({ apiVersion, kind, namespace, name }) {
    const { apiGroup, resourceVersion } = parseApiVersion(apiVersion)
    const endpoint = getEndpoint(this.client, {
      apiGroup,
      resourceVersion,
      kind,
      namespace,
      name
    }, true)

    return await endpoint.getObjectStream()
  }

  /**
   * @typedef {Object} WaitConditionRequestInfo
   * @property {String} apiVersion Kubernetes resource API version
   * @property {String} kind Kubernetes resource kind
   * @property {String} [namespace] Kubernetes resource namespace
   * @property {String} [name] Kubernetes resource name
   * @property {Function} [callback] Condition check callback
   */

  /**
   * @typedef {Object} WaitConditionCallbackResult
   * @property {Boolean} condition Wether the condition was met or not
   * @property {any} res Result to return
   */

  /**
   * Watch resources until a condition is true.
   * The callback must return a Promise resolving to an object of
   * type {@link WaitConditionCallbackResult}
   *
   * @param {WaitConditionRequestInfo} params
   * @returns {Promise<any>} Result returned by the first callback that met its condition
   */
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

  /**
   * @typedef PatchRequestInfo
   * @property {String} apiVersion Kubernetes resource API version
   * @property {String} kind Kubernetes resource kind
   * @property {String} [namespace] Kubernetes resource namespace
   * @property {String} name Kubernetes resource name
   * @property {Object} patch Kubernetes Resource Merge Patch
   */

  /**
   * Patch a Kubernetes resource with a {@link https://tools.ietf.org/html/rfc7386|JSON Merge Patch}.
   *
   * @param {PatchRequestInfo} params
   * @returns {Promise<Object>} Patched Kubernetes resource
   */
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

  /**
   * @typedef {Object} DeleteRequestInfo
   * @property {String} apiVersion Kubernetes resource API version
   * @property {String} kind Kubernetes resource kind
   * @property {String} [namespace] Kubernetes resource namespace
   * @property {String} name Kubernetes resource name
   */

  /**
   * Delete a single Kubernetes resources
   *
   * @param {DeleteRequestInfo} params
   * @returns {Promise<Object>} Deleted Kubernetes resource
   */
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

  /**
   * @typedef ExecRequestInfo
   * @property {String} namespace Kubernetes Pod namespace
   * @property {String} name Kubernetes Pod name
   * @property {String} command Command to execute inside the Pod's container
   * @property {String} [container] Pod container name (mandatory if more than one container)
   */

  /**
   * Execute a command in a Pod's container.
   *
   * @param {ExecRequestInfo} params
   * @returns {Promise<String>} Command output
   */
  async exec({ namespace, name, command, container }) {
    const { apiGroup, resourceVersion } = parseApiVersion('v1')
    const endpoint = getEndpoint(this.client, {
      apiGroup,
      resourceVersion,
      kind: 'Pod',
      namespace,
      name
    })
    return response.unwrap(await endpoint.exec.post({
      qs: {
        command,
        container,
        stdout: true,
        stderr: true
      }
    }))
  }

  /**
   * @typedef LogRequestInfo
   * @property {String} namespace Kubernetes Pod namespace
   * @property {String} name Kubernetes Pod name
   * @property {String} [container] Pod container name (mandatory if more than one container)
   */

  /**
   * Get Pod's container logs
   *
   * @param {LogRequestInfo} params
   * @returns {Promise<String>} Pod's container logs
   */
  async logs({ namespace, name, container }) {
    const { apiGroup, resourceVersion } = parseApiVersion('v1')
    const endpoint = getEndpoint(this.client, {
      apiGroup,
      resourceVersion,
      kind: 'Pod',
      namespace,
      name
    })
    return response.unwrap(await endpoint.log.get({
      qs: {
        container
      }
    }))
  }
}

KubeInterface.Error = KubeError

module.exports = KubeInterface
