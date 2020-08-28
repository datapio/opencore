module.exports = async () => ({
  requires: ['kubectl'],
  interface: ({ kubectl }) => ({
    tasks: {
      create: async (name, spec) => {
        return await kubectl.api.create({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Task',
          metadata: {
            name,
            namespace: kubectl.namespace
          },
          spec
        })
      },
      list: async () => {
        return await kubectl.api.list({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Task',
          namespace: kubectl.namespace
        })
      },
      get: async name => {
        return await kubectl.api.get({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Task',
          namespace: kubectl.namespace,
          name
        })
      },
      patch: async (name, patch) => {
        return await kubectl.api.patch({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Task',
          namespace: kubectl.namespace,
          name,
          patch
        })
      },
      delete: async name => {
        return await kubectl.api.delete({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Task',
          namespace: kubectl.namespace,
          name
        })
      },
      run: async (name, { workspaces, params, resources }) => {
        const scope = {
          trun: await kubectl.api.create({
            apiVersion: 'tekton.dev/v1alpha1',
            kind: 'TaskRun',
            metadata: {
              generateName: `run-${name}-`,
              namespace: kubectl.namespace
            },
            spec: {
              workspaces,
              params,
              resources,
              taskRef: { name }
            }
          })
        }

        return {
          cancel: async () => {
            return await kubectl.api.patch({
              apiVersion: scope.trun.apiVersion,
              kind: scope.trun.kind,
              namespace: kubectl.namespace,
              name: scope.trun.metadata.name,
              patch: {
                spec: {
                  status: 'TaskRunCancelled'
                }
              }
            })
          },
          watch: async () => {
            scope.trun = await kubectl.api.wait_condition({
              apiVersion: scope.trun.apiVersion,
              kind: scope.trun.kind,
              namespace: kubectl.namespace,
              name: scope.trun.metadata.name,
              callback: async object => {
                scope.trun = object
                return scope.trun.status.completionTime
              }
            })

            if (scope.trun.status.conditions.filter(cond => cond.type === 'Succeeded').length === 0) {
              throw new Error('Task execution failed')
            }
          }
        }
      }
    },
    pipelines: {
      create: async (name, spec) => {
        return await kubectl.api.create({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Pipeline',
          metadata: {
            name,
            namespace: kubectl.namespace
          },
          spec
        })
      },
      list: async () => {
        return await kubectl.api.list({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Pipeline',
          namespace: kubectl.namespace
        })
      },
      get: async name => {
        return await kubectl.api.get({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Pipeline',
          namespace: kubectl.namespace,
          name
        })
      },
      patch: async (name, patch) => {
        return await kubectl.api.patch({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Pipeline',
          namespace: kubectl.namespace,
          name,
          patch
        })
      },
      delete: async name => {
        return await kubectl.api.delete({
          apiVersion: 'tekton.dev/v1alpha1',
          kind: 'Pipeline',
          namespace: kubectl.namespace,
          name
        })
      },
      run: async (name, { workspaces, params, resources }) => {
        const scope = {
          prun: await kubectl.api.create({
            apiVersion: 'tekton.dev/v1alpha1',
            kind: 'PipelineRun',
            metadata: {
              generateName: `run-${name}-`,
              namespace: kubectl.namespace
            },
            spec: {
              workspaces,
              params,
              resources,
              pipelineRef: { name }
            }
          })
        }

        return {
          cancel: async () => {
            return await kubectl.api.patch({
              apiVersion: scope.prun.apiVersion,
              kind: scope.prun.kind,
              namespace: kubectl.namespace,
              name: scope.prun.metadata.name,
              patch: {
                spec: {
                  status: 'PipelineRunCancelled'
                }
              }
            })
          },
          watch: async () => {
            scope.prun = await kubectl.api.wait_condition({
              apiVersion: scope.prun.apiVersion,
              kind: scope.prun.kind,
              namespace: kubectl.namespace,
              name: scope.prun.metadata.name,
              callback: async object => {
                scope.prun = object
                return scope.prun.status.completionTime
              }
            })

            if (scope.prun.status.conditions.filter(cond => cond.type === 'Succeeded').length === 0) {
              throw new Error('Pipeline execution failed')
            }
          }
        }
      }
    }
  })
})
