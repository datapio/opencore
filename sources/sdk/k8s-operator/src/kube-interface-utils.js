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

module.exports = {
  KubeError,
  defaultCallback,
  parseApiVersion,
  getEndpoint,
  response,
  makeReviewer
}
