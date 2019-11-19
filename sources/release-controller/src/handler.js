const getPipeline = (object) => ({
    apiVersion: 'tekton.dev/v1alpha1',
    kind: 'PipelineRun',
    metadata: {
        name: `${object.spec.repository.name}-${object.spec.revision}`
    },
    spec: {
        pipelineSpec: {
            resources: [
                {
                    name: 'source-repo',
                    type: 'git'
                }
            ],
            params: [
                {
                    name: 'environment',
                    type: 'string'
                }
            ],
            tasks: object.spec.artifacts.map(
                (artifact) => ({
                    name: `${artifact.type}-artifact`,
                    taskRef: {
                        name: `${artifact.type}-artifact`
                    },
                    resources: {
                        inputs: [
                            {
                                name: 'source-repo',
                                resource: 'source-repo'
                            }
                        ]
                    },
                    params: [
                        {
                            name: 'environment',
                            value: '$(params.environment)'
                        },
                        {
                            name: 'name',
                            value: artifact.name
                        },
                        {
                            name: 'path',
                            value: artifact.path
                        },
                        {
                            name: 'params',
                            value: JSON.stringify(artifact.params)
                        }
                    ]
                })
            )
        },
        resources: [
            {
                name: 'source-repo',
                resourceSpec: {
                    type: 'git',
                    params: [
                        {
                            name: 'url',
                            value: object.spec.repository.url
                        },
                        {
                            name: 'revision',
                            value: object.spec.revision
                        }
                    ]
                }
            }
        ],
        params: [
            {
                name: 'environment',
                value: object.spec.environment
            }
        ]
    }
})

module.exports = (request, response) => {
    const { parent } = request.body
    const pipeline = getPipeline(parent)
    response.send({ status: {}, children: [pipeline] })
}
