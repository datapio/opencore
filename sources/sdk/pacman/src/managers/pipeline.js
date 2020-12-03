// @flow

import type { Pipeline } from '../api'
import type { Event } from './config'
import contextManager from './context'
import helperManager from './helpers'
import profileManager from './profile'
import toolManager from './tools'

export default {
  load: (modules: Array<string>): Promise<Array<Pipeline>> => {
    return Promise.all(modules.map(module => import(module)))
  },
  run: async (pipeline: Pipeline, event: Event): Promise<void> => {
    const context = contextManager.get(pipeline)
    const helpers = await helperManager.init()
    const profile = await profileManager.get(context, pipeline, event, helpers)
    const tools = await toolManager.get(profile)
    helperManager.addTools(helpers, tools)
    await helperManager.addKube(helpers, profile)

    const values = await profile.values(helpers)
    await profileManager.integration(profile, pipeline, helpers, values)
    await profileManager.deployment(profile, pipeline, helpers, values)
  }
}
