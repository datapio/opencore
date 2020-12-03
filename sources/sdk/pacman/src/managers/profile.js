// @flow

import type { Pipeline, Profile, Helpers, Values, Component } from '../api'
import type { Event } from './config'
import type { Context } from './context'
import mergeOptions from 'merge-options'

const capitalize = (str: string): string =>
  str.charAt(0).toUpperCase() + str.slice(1)

const defaultHandler = async function(context) {
  return context.profile()
}

export default {
  get: (context: Context, pipeline: Pipeline, event: Event, helpers: Helpers): Promise<Profile> => {
    const handlerName = `on${capitalize(event.kind)}`
    const handler = pipeline[handlerName] || defaultHandler
    return handler(context, helpers)
  },
  integration: async (profile: Profile, pipeline: Pipeline, helpers: Helpers, values: Values): Promise<void> => {
    if (profile.integration) {
      const components = Object.values(pipeline.components)
      const waiters = []
      const process = async (component) => {
        const localValues = mergeOptions(
          await component.defaultValues(),
          values
        )
        await component.integration(helpers, localValues)
      }

      for (const name in pipeline.components) {
        waiters.push(process(pipeline.components[name]))
      }

      await Promise.all(waiters)
    }
  },
  deployment: async (profile: Profile, pipeline: Pipeline, helpers: Helpers, values: Values): Promise<void> => {
    if (profile.deployment) {
      const components = Object.values(pipeline.components)
      const waiters = []
      const process = async (component) => {
        const localValues = mergeOptions(
          await component.defaultValues(),
          values
        )
        const resources = await component.deployment(helpers, localValues)
        // TODO: apply resources
      }

      for (const name in pipeline.components) {
        waiters.push(process(pipeline.components[name]))
      }

      await Promise.all(waiters)
    }
  }
}