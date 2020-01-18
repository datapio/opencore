import http from 'http'
import handlers from './handlers'

import { port } from './config'

http.createServer(handlers).listen(port || 8000)
