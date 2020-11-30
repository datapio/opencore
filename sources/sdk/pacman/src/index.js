import { Pipeline } from './api'

const main = async () => {
  const argv = process.argv.slice(2)

  return do {
    if (argv.length !== 1) {
      console.error('Usage: datapio-pacman [pipeline-module]')
      1
    }
    else {
      const [module] = argv
      const pipeline: Pipeline = await import(module)
      console.log(pipeline)
    }
  }
}

main().catch(console.error)
