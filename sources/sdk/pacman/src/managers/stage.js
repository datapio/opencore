// @flow

import type { Pipeline, Helpers, Values, Component, Context } from '../api'
import type { Event } from './config'
import mergeOptions from 'merge-options'

type StageFunction = (component: Component, values: Values) => Promise<any>

const componentStage = (values: Values, stage: StageFunction) =>
  async (component: Component) => {
    const localValues = mergeOptions(
      await component.defaultValues(),
      values
    )

    return await stage(component, values)
  }

const runStage = async (pipeline: Pipeline, helpers: Helpers, values: Values, stage: StageFunction): Promise<Array<any>> => {
  const components = Object.values(pipeline.components)
  const waiters = []
  const process = componentStage(values, stage)

  for (const name in pipeline.components) {
    waiters.push(process(pipeline.components[name]))
  }

  return await Promise.all(waiters)
}

export default {
  integration: async (pipeline: Pipeline, helpers: Helpers, values: Values): Promise<void> => {
    await runStage(pipeline, helpers, values, async (component, values) => {
      await component.integration(helpers, values)
    })
  },
  deployment: async (pipeline: Pipeline, helpers: Helpers, values: Values): Promise<void> => {
    const resourceSets = await runStage(pipeline, helpers, values, async (component, values) => {
      return await component.deployment(helpers, values)
    })
    const resources = [].concat(...resourceSets)

    const { kubectl } = helpers

    try {
      const releaseObject = await kubectl.get({
        apiVersion: 'v1',
        kind: 'Secret',
        name: `datapio-release-${pipeline.release.name}`,
        namespace: pipeline.release.namespace
      })
    }
    catch (err) {
      // TODO: create releaseObject
    }

    try {
      const prevRevision = await kubectl.get({
        apiVersion: 'v1',
        kind: 'Secret',
        name: releaseObject.spec.currentRevision,
        namespace: pipeline.release.namespace
      })
    }
    catch (err) {
      // TODO: handle case when no previous revision
    }

    const newRevision = await kubectl.create({
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        generateName: `datapio-revision-${pipeline.release.name}-`,
        namespace: pipeline.release.namespace
      },
      stringData: Object.fromEntries(resources.map(rsrc => [
        rsrc.metadata.name,
        JSON.stringify(rsrc)
      ]))
    })

    // TODO: diff between prevRevision and newRevision
    // TODO: delete missing resources from newRevision
    // TODO: patch resources present in both revisions
    // TODO: create missing ressources from prevResion

    await kubectl.patch({
      apiVersion: 'v1',
      kind: 'Secret',
      name: releaseObject.metadata.name,
      namespace: releaseObject.metadata.namespace,
      patch: {
        spec: {
          currentRevision: newRevision.metadata.name
        }
      }
    })
  }
}
