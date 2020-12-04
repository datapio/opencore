// @flow

import { promises as fs } from 'fs'

export type Configuration = {
  pipelines: Array<string>
}

export type Event = {
  kind: 'push' | 'pull_request' | 'local'
}

const parseFile = async (filename: string): any =>
  JSON.parse(await fs.readFile(filename, 'utf-8'))

export default {
  get: (
    configPath: string,
    eventPath: string
  ): Promise<[Configuration, Event]> => {
    return Promise.all([
      parseFile(configPath),
      parseFile(eventPath)
    ])
  }
}

