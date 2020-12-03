// @flow

import type { Profile, ToolDefinitionArray } from '../api'

export default {
  get: async (profile: Profile): Promise<Array<[string, any]>> => {
    const tools: ToolDefinitionArray = await profile.tools()
    const entries = await Promise.all(tools.map(
      async ({ name, module, options }): Promise<[string, any]> => {
        const makeTool = await import(module)
        return [name, await makeTool(options)]
      }
    ))

    return entries
  }
}
