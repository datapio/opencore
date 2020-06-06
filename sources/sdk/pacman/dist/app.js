'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var fs = require('fs');
var vm = _interopDefault(require('vm'));

const build = async opts => console.log('docker.build:', opts);
const push = async opts => console.log('docker.push:', opts);

var docker = /*#__PURE__*/Object.freeze({
  __proto__: null,
  build: build,
  push: push
});

const deploy = async opts => console.log('helm.deploy:', opts);

var helm = /*#__PURE__*/Object.freeze({
  __proto__: null,
  deploy: deploy
});

const read = async opts => {
  console.log('vault.read:', opts);
  return {};
};

var vault = /*#__PURE__*/Object.freeze({
  __proto__: null,
  read: read
});

var git = {
  commit: () => ({
    sha: 'test'
  }),
  branch: () => 'master'
};

var plugins = {
  docker,
  helm,
  vault,
  git
};

const make_context = async () => {
  const state = {
    pipelineSpec: null
  };

  const tool = name => plugins[name] || require(`@datapio-pacman/plugin-${name}`);

  const pipeline = spec => {
    state.pipelineSpec = spec;
  };

  const secret = async name => `some-secret-${name}`;

  return {
    state,
    exports: {
      tool,
      pipeline,
      secret
    }
  };
};

const run_stage = async (stage, env) => {
  if (stage.when(env)) {
    console.log('run_stage:', stage.name);
    await stage.script(env);
  } else {
    console.log('run_stage:', stage, '(skip)');
  }
};

const run_pipeline = async filename => {
  let filehandle;

  try {
    filehandle = await fs.promises.open(filename, 'r');
    const code = await filehandle.readFile();
    const context = await make_context();
    vm.runInNewContext(code, context.exports);
    const env = await context.state.pipelineSpec.environment();

    for (let stage of context.state.pipelineSpec.stages) {
      await run_stage(stage, env);
    }
  } finally {
    if (filehandle !== undefined) await filehandle.close();
  }
};

run_pipeline('examples/pipeline.js');
