const { execute_manifest } = require('./sandbox.js')


execute_manifest(
  process.env.PACMAN_WORKSPACE_PVC,
  process.env.PACMAN_MANIFEST_PATH
)
