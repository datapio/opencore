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


const makeReviewer = (kubectl, reviewKind) =>
  async ({ apiVersion, kind, namespace, verb }) => {
    const { apiGroup } = parseApiVersion(apiVersion)
    const resp = await kubectl.create({
      apiVersion: 'authorization.k8s.io/v1',
      kind: reviewKind,
      spec: {
        resourceAttributes: {
          group: apiGroup,
          resource: kind.toLowerCase(),
          verb,
          namespace
        }
      }
    })

    return resp.status
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

  async create(...resources) {
    return await Promise.all(resources
      .map(resource => ({
        kind: resource.kind,
        namespace: resource.metadata?.namespace,
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

    return await endpoint.getObjectStream()
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

  async canI(meta) {
    const reviewer = makeReviewer(this, 'SelfSubjectAccessReview')
    const review = await reviewer(meta)
    return review.allowed
  }

  async canThey(meta) {
    const reviewKind = meta.namespace ? 'LocalSubjectAccessReview' : 'SubjectAccessReview'
    const reviewer = makeReviewer(this, reviewKind)
    const review = await reviewer(meta)
    return review.allowed.allowed
  }

  async myAccessRules({ scopes = [] }) {
    const { apiGroup } = parseApiVersion(apiVersion)
    const resp = await this.create({
      apiVersion: 'authorization.k8s.io/v1',
      kind: 'SelfSubjectRulesReview',
      spec: {
        scopes
      }
    })

    return resp.status
  }
}

KubeInterface.Error = KubeError

module.exports = KubeInterface
