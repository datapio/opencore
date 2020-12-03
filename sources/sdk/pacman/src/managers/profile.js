// @flow

import type { Pipeline, Profile, Helpers, Context } from '../api'
import type { Event } from './config'

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
  }
}