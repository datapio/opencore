const express = require('express')
const handler = require('./handler.js')

const app = express()
app.use(express.bodyParser())
app.post('/sync', handler)
app.listen(8000, () => console.log('Listening on 0.0.0.0:8000'))
