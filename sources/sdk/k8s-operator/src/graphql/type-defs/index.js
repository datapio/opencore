const { gql } = require('apollo-server-express')
const path = require('path')
const fs = require('fs')

const requireTypeDef = name =>
  gql(fs.readFileSync(
    path.resolve(__dirname, `./${name}.graphql`),
    { encoding: 'utf8' }
  ))

module.exports = {
  Label: requireTypeDef('label'),
  Annotation: requireTypeDef('annotation'),
  NamespacedResource: requireTypeDef('namespaced-resource'),
  ClusterResource: requireTypeDef('cluster-resource'),
  ResourceField: requireTypeDef('resource-field'),
  Collection: requireTypeDef('collection')
}
