import { operator, adopt_resource } from '@datapio/k8s-operator'
import { make_engine } from '@datapio/amqp-engine'

operator({
  lifecycle: {
    initialize: async (kubectl) => ({
      rabbitmq: await make_engine({
        url: process.env.RABBITMQ_URL,
        consumers: {
          history: {
            queue: process.env.RABBITMQ_HISTORY_QUEUE,
            handler: async (publishers, pipeline_run_request) => {
              const runrequests = await kubectl.list({
                apiVersion: 'datap.io/v1alpha1',
                kind: 'PipelineRunRequest',
                name,
                namespace,
                fieldSelector: {
                  'status.archived': true
                }
              })

              await Promise.all(runrequests
                .sort(by_completion_time)
                .slice(0, 0 - parseInt(process.env.ARCHIVER_HISTORY_SIZE || '10'))
                .map(async ({ apiVersion, kind, metadata: { name, namespace }}) =>
                  await kubectl.delete({ apiVersion, kind, name, namespace })
                )
              )

              const { name, namespace } = pipeline_run_request.metadata
              await kubectl.patch({
                apiVersion: 'datap.io/v1alpha1',
                kind: 'PipelineRunRequest',
                name,
                namespace,
                status: {
                  archived: true
                }
              })
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
