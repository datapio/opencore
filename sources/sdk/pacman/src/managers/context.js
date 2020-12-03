// @flow

import type { Pipeline, Profile, Context } from '../api'
import { KubeConfig } from 'kubernetes-client'

const defaultProfile: Profile = {
  async tools() {
    return []
  },
  async kubeConfig() {
    return new KubeConfig()
  },
  async values() {
    return {}
  },
  integration: false,
  deployment: false
}

export default {
  get: (pipeline: Pipeline): Context => ({
    profile: (name, override = {}) => {
      const profile = pipeline.profiles[name] || defaultProfile

      if (typeof override.integration === 'boolean') {
        profile.integration = override.integration
      }

      if (typeof override.deployment === 'boolean') {
        profile.deployment = override.deployment
      }

      return profile
    }
  })
}
