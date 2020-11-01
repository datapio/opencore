const through = require('through')

const context = {
  world: null
}

module.exports = {
  setUp: () => {
    context.world = {
      stream: through(),
      watcher: {
        added: false,
        modified: false,
        deleted: false
      }
    }
  },
  withWorld: cb => cb(context.world)
}
