// @flow

import type { Pipeline, Helpers, Values, Component, Context } from '../api'
import type { Event } from './config'
import mergeOptions from 'merge-options'
import slugify from 'slugify'

slugify.extend({
  '.': '-',
  '/': '_'
})

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

    const newRevision = await kubectl.create({
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        generateName: `datapio-revision-${pipeline.release.name}-`,
        namespace: pipeline.release.namespace,
        annotations: {
          'app.kubernetes.io/managed-by': 'datapio',
          'app.datap.io/kind': 'revision',
          'app.datap.io/release': pipeline.release.name
        }
      },
      stringData: Object.fromEntries(resources.map(rsrc => {
        const { apiVersion, kind, metadata: { name, namespace } } = rsrc

        return [
          slugify(`${apiVersion}_${kind}_${namespace}_${name}`),
          JSON.stringify(rsrc)
        ]
      }))
    })

    const releaseObject = {
      name: `datapio-release-${pipeline.release.name}`,
      revision: newRevision.metadata.name
    }

    try {
      await kubectl.patch({
        apiVersion: 'v1',
        kind: 'Secret',
        name: releaseObject.name,
        namespace: pipeline.release.namespace,
        patch: {
          spec: {
            currentRevision: releaseObject.revision
          }
        }
      })
    }
    catch (err) {
      await kubectl.create({
        apiVersion: 'v1',
        kind: 'Secret',
        metadata: {
          name: releaseObject.name,
          namespace: pipeline.release.namespace,
          annotations: {
            'app.kubernetes.io/managed-by': 'datapio',
            'app.datap.io/kind': 'release'
          }
        },
        spec: {
          currentRevision: releaseObject.revision
        }
      })
    }
  }
}
