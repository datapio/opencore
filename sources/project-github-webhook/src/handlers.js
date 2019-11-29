import deployManifest from './k8s'

import { secret } from './conf'

import createHandler from 'github-webhook-handler'

const h404 = (res) => () => {
    res.statusCode = 404
    res.end('no such location')
}

const error = (err) => {
    console.error('Error: ', err.message)
}

const push = deployManifest

export default (req, res) => {
    const handler = createHandler({ path: '/', secret })
    handler.on('error', error)
    handler.on('push', push)
    handler(req, res, h404(res))
    return handler
}
