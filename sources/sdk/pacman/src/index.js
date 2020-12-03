// @flow

import Api from 'sywac/api'
import configManager from './managers/config'
import pipelineManager from './managers/pipeline'

const cli = new Api()
  .positional('<config:file>', {
    paramsDesc: 'Path to configuration file',
    mustExist: true
  })
  .positional('<event:file>', {
    paramsDesc: 'Path to JSON payload describing the event',
    mustExist: true
  })

const main = async (): Promise<number> => {
  const argv = await cli.parseAndExit()
  const [config, event] = await configManager.get(argv.config, argv.event)

  const pipelines = await pipelineManager.load(config.pipelines)
  await Promise.all(pipelines.map(
    pipeline => pipelineManager.run(pipeline, event)
  ))

  return 0
}

main()
  .then((exitCode: number) => process.exit(exitCode))
  .catch((err: Error) => {
    console.error(err)
    process.exit(1)
  })
