// @flow

import { KubeConfig } from 'kubernetes-client'

export type ToolDefinition = {
  name: string,
  module: string,
  options: any
}

export type ToolDefinitionArray = Array<ToolDefinition>

export type Resource = {
  apiVersion: string,
  kind: string,
  metadata: {},
  spec?: {},
  status?: {}
}

export type ResourceArray = Array<Resource>

export type Helpers = {
  [propName: string]: any
}
export type Values = {
  [propName: string]: any
}

export type Profile = {
  integration: boolean,
  deployment: boolean,
  tools: () => Promise<ToolDefinitionArray>,
  kubeConfig: (helpers: Helpers) => Promise<KubeConfig>,
  values: (helpers: Helpers) => Promise<Values>
}

export type ProfileSet = {
  [name: string]: Profile
}

export type ProfileOverride = {
  integration?: boolean,
  deployment?: boolean
}

export type Context = {
  profile: (name: string, override: ProfileOverride) => Profile
}

export type Component = {
  defaultValues: () => Promise<{}>,
  integration: (helpers: Helpers, values: Values) => Promise<void>,
  deployment: (helpers: Helpers, values: Values) => Promise<ResourceArray>
}

export type ComponentSet = {
  [name: string]: Component
}

export type Release = {
  name: string,
  namespace: string
}

export type Pipeline = {
  release: Release,
  components: ComponentSet,
  profiles: ProfileSet,

  onPush?: (context: Context, helpers: Helpers) => Promise<Profile>,
  onPullRequest?: (context: Context, helpers: Helpers) => Promise<Profile>,
  onLocal?: (context: Context, helpers: Helpers) => Promise<Profile>
}
