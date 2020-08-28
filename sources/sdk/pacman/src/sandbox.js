const fs = require('fs')
const vm = require('vm')
const builtins = require('./builtins/index.js')


const no_interface = () => ({})
const no_environment = async () => ({})
const always = async () => true
const nothing = async () => null

const validate_spec = spec => ({
  name: spec.name || 'no-name',
  tools: spec.tools || [],
  definitions: spec.definitions || {},
  environment: spec.environment || no_environment,
  stages: (spec.stages || []).map(stage => ({
    name: stage.name || 'no-name',
    when: stage.when || always,
    script: stage.script || nothing
  }))
})

const parse_manifest = filename => {
  console.log(`level=info timestamp=${Date.now()} manifest=${filename} event=requested`)
  const pipelines = new Set()
  const exports = {}

  try {
    // eslint-disable-next-line no-sync
    const code = fs.readFileSync(filename, { encoding: 'utf-8', flag: 'r' })

    const context = {
      pipeline: spec => {
        pipelines.add(validate_spec(spec))
      },
      include: inc_filename => {
        const mod = parse_manifest(inc_filename)

        if (mod === null) {
          throw new Error(`Failed to include manifest: ${inc_filename}`)
        }

        mod.pipelines.forEach(spec => pipelines.add(spec))
        return mod.exports
      },
      fs: fs.promises,
      sleep: async ms => new Promise(resolve => setTimeout(resolve, ms)),
      parallelMap: async (arr, callback) => {
        return await Promise.all(arr.map(callback))
      },
      sequentialMap: async (arr, callback) => {
        const result = []

        for (const item of arr) {
          result.push(await callback(item))
        }

        return result
      },
      exports
    }

    vm.runInNewContext(code, context)
  }
  catch (err) {
    console.log(`level=info timestamp=${Date.now()} manifest=${filename} event=loading-failed`)
    console.error(err)
    return null
  }

  return { pipelines: [...pipelines], exports }
}


const import_tool = async (cache, name) => {
  if (!cache[name]) {
    const make_tool = builtins[name] || require(`@datapio/pacman-plugin-${name}`)
    const tool = await make_tool()

    const make_interface = tool.interface || no_interface
    const deps = tool.requires || []
    const tools = {}

    for (const dep of deps) {
      tools[dep] = await import_tool(cache, dep)
    }

    cache[name] = make_interface(tools)
  }

  return cache[name]
}


const run_in_context = (exports, callback) =>
  async (...args) =>
    await vm.runInNewContext('self(...arguments)', {
      self: callback,
      arguments: args,
      ...exports
    })


const run_pipeline = async (workspace_pvc, exports, spec) => {
  console.log(`level=info timestamp=${Date.now()} pipeline=${spec.name} event=started`)

  const tools = {}

  for (const name of spec.tools) {
    await import_tool(tools, name)
    console.log(`level=info timestamp=${Date.now()} pipeline=${spec.name} tool=${name} event=imported`)
  }

  const get_env = run_in_context(exports, spec.environment)
  const env = await get_env(workspace_pvc, tools)
  console.log(`level=info timestamp=${Date.now()} pipeline=${spec.name} event=environment-loaded`)

  for (const stage of spec.stages) {
    const when = run_in_context(exports, stage.when)

    if (await when(env, tools)) {
      console.log(`level=info timestamp=${Date.now()} pipeline=${spec.name} stage=${stage.name} event=started`)

      try {
        const run_stage = run_in_context(exports, stage.script)
        await run_stage(env, tools)
        console.log(`level=info timestamp=${Date.now()} pipeline=${spec.name} stage=${stage.name} event=succeeded`)
      }
      catch (err) {
        console.log(`level=error timestamp=${Date.now()} pipeline=${spec.name} stage=${stage.name} event=failed`)
        console.error(err)
        return false
      }
    }
    else {
      console.log(`level=info timestamp=${Date.now()} pipeline=${spec.name} stage=${stage.name} event=skipped`)
    }
  }

  console.log(`level=info timestamp=${Date.now()} pipeline=${spec.name} event=succeeded`)

  return true
}


const execute_manifest = async (workspace_pvc, filename) => {
  const module = parse_manifest(filename)

  if (module === null) {
    throw new Error(`Failed to parse manifest: ${filename}`)
  }

  return await Promise.all(
    module.pipelines.map(
      async spec => await run_pipeline(workspace_pvc, module.exports, spec)
    )
  )
}

module.exports = { execute_manifest }