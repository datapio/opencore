import http from 'http'
import handlers from './handlers'

const serve = () => {
  http.createServer(handlers).listen(8000)
}

export default serve
