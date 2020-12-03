// @flow

import { KubeInterface } from '@datapio/sdk-k8s-operator'
import type { Helpers, Profile } from '../api'

const makeRepository = async () => {}

export default {
  init: async (): Promise<Helpers> => {
    return {
      repository: await makeRepository()
    }
  },
  addTools: (helpers: Helpers, tools: Array<[string, any]>): void => {
    tools.map(([name, tool]) => {
      helpers[name] = tool
    })
  },
  addKube: async (helpers: Helpers, profile: Profile): Promise<void> => {
    const kubeConfig = await profile.kubeConfig(helpers)
    helpers.kubectl = new KubeInterface({
      createCRDS: false,
      config: kubeConfig
    })
    await helpers.kubectl.load()
  }
}
