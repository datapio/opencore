import { operator, adopt_resource } from '@datapio/k8s-operator'
import { make_engine } from '@datapio/amqp-engine'

operator({
  lifecycle: {
    initialize: async (kubectl) => ({
      rabbitmq: await make_engine({
        url: process.env.RABBITMQ_URL,
        publishers: {
          history: {
            queue: process.env.RABBITMQ_HISTORY_QUEUE
          }
        },
        consumers: {
          worker: {
            queue: process.env.RABBITMQ_WORKER_QUEUE,
            handler: async ({ history }, pipeline_run_request) => {
              const { metadata: { name, namespace } } = pipeline_run_request.metadata
              const {
                pipeline,
                server,
                extraResources,
                resources,
                workspaces,
                params
              } = pipeline_run_request.spec

              await kubectl.create(...extraResources.map(
                resource => adopt_resource(pipeline_run_request, resource)
              ))

              const prun = await kubectl.create(adopt_resource({
                apiVersion: 'tekton.dev/v1alpha1',
                kind: 'PipelineRun',
                metadata: {
                  name,
                  namespace
                },
                spec: {
                  pipelineRef: {
                    name: pipeline
                  },
                  resources,
                  workspaces,
                  params
                }
              }))

              const final_prun_req = await kubectl.wait_condition({
                apiVersion: pipeline_run_request.apiVersion,
                kind: pipeline_run_request.kind,
                name,
                namespace,
                callback: async object => {
                  const prun_req = await kubectl.patch({
                    apiVersion: pipeline_run_request.apiVersion,
                    kind: pipeline_run_request.kind,
                    name,
                    namespace,
                    patch: {
                      status: {
                        pipelineRunStatus: object.status
                      }
                    }
                  })

                  return {
                    condition: object.status.completionTime,
                    result: prun_req
                  }
                }
              })

              await history.send(final_prun_req)
            }
          }
        }
      })
    }),
    terminate: async (kubectl, { rabbitmq }) => {
      await rabbitmq.cancel()
    }
  }
})
