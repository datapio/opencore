const testWorld = require('./test-world')

const mock = require('mock-require')

mock('test!world', testWorld)

const http = require('./http')
const https = require('./https')
const fs = require('./fs')
const terminus = require('./terminus')
const kubernetesClient = require('./kubernetes-client')
const backendRequest = require('./kubernetes-client-backend-request')
const apolloServer = require('./apollo-server')
const express = require('./express')

mock('http', http)
mock('https', https)
mock('fs', fs)
mock('@godaddy/terminus', terminus)
mock('kubernetes-client', kubernetesClient)
mock('kubernetes-client/backends/request', backendRequest)
mock('apollo-server-express', apolloServer)
mock('express', express)
