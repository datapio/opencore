const sinon = require('sinon')

const applyMiddleware = sinon.stub()
const gql = sinon.stub()

class ApolloServer {
  constructor() {
    this.applyMiddleware = applyMiddleware
  }
}

module.exports = {
  stubs: { applyMiddleware },
  ApolloServer,
  gql
}
