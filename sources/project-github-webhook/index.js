var http = require('http');
var createHandler = require('github-webhook-handler');
const deploymentManifest = require('./github-webhook-deployment.json');
const yaml = require('js-yaml');
const fs   = require('fs');

// let kubernetes-client configure automatically by trying the KUBECONFIG environment variable first, then ~/.kube/config, then an in-cluster service account, and lastly settling on a default proxy configuration
const client = new Client({ version: '1.13' })

// Get document, or throw exception on error
function readConf (path) {
  let result
  try {
    result = yaml.safeLoad(fs.readFileSync(path, 'utf8'));
  } catch (e) {
    console.log(e);
  }
  return result
}

const conf = readConf('config.yml');

var handler = createHandler({ ...config }); // path and secret

http.createServer(function (req, res) {
  handler(req, res, function (err) {
    res.statusCode = 404
    res.end('no such location')
  })
}).listen(8000);

handler.on('error', function (err) {
  console.error('Error:', err.message)
});

handler.on('push', async function () {
  await client.api.v1.namespaces('default').deployments.post({ body: deploymentManifest })
});
