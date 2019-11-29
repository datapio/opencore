import deployManifest from './k8s'

import { secret } from './conf'

const h404 = res => err => {
  res.statusCode = 404
  res.end('no such location')
}

const error = err => {
  console.error('Error: ', err.message)
}

const push = deployManifest

export default = (req, res) => {
  const handler = createHandler({ path: '/', secret })
  handler.on('error', error)
  handler.on('push', push)
  hander(req, res, h404(res))
  return handler
}
