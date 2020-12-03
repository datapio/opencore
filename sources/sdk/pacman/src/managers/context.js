// @flow

import type { Pipeline, Profile } from '../api'
import { KubeConfig } from 'kubernetes-client'

export type ProfileTriggers = {
  integration?: boolean,
  deployment?: boolean
}

export type Context = {
  profile: (name: string, triggers: ProfileTriggers) => Profile
}

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
    profile: (name, triggers = {}) => {
      const profile = pipeline.profiles[name] || defaultProfile

      if (typeof triggers.integration === 'boolean') {
        profile.integration = triggers.integration
      }

      if (typeof triggers.deployment === 'boolean') {
        profile.deployment = triggers.deployment
      }

      return profile
    }
  })
}
