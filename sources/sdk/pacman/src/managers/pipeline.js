// @flow

import type { Pipeline } from '../api'
import type { Event } from './config'
import contextManager from './context'
import helperManager from './helpers'
import profileManager from './profile'
import toolManager from './tools'
import stageManager from './stage'

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

    if (profile.integration) {
      await stageManager.integration(pipeline, helpers, values)
    }

    if (profile.deployment) {
      await stageManager.deployment(pipeline, helpers, values)
    }
  }
}
