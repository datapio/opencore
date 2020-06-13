exports.images = sha => [
  {
    dockerfile: 'containers/pipelinerunserver-archiver.dockerfile',
    snapshot_tag: `datapio/pipelinerunserver-archiver:${sha}`,
    latest_tag: 'datapio/pipelinerunserver-archiver:latest',
  },
  {
    dockerfile: 'containers/pipelinerunserver-worker.dockerfile',
    snapshot_tag: `datapio/pipelinerunserver-worker:${sha}`,
    latest_tag: 'datapio/pipelinerunserver-worker:latest'
  },
  {
    dockerfile: 'containers/pipelinerunserver-operator.dockerfile',
    snapshot_tag: `datapio/pipelinerunserver-operator:${sha}`,
    latest_tag: 'datapio/pipelinerunserver-operator:latest'
  },
  {
    dockerfile: 'containers/pipeline-executor.dockerfile',
    snapshot_tag: `datapio/pipeline-executor:${sha}`,
    latest_tag: 'datapio/pipeline-executor:latest'
  },
  {
    dockerfile: 'containers/project-operator.dockerfile',
    snapshot_tag: `datapio/project-operator:${sha}`,
    latest_tag: 'datapio/project-operator:latest'
  }
]

exports.image_builder = (env, { docker }) =>
  async image =>
    await docker.build({
      dockerfile: image.dockerfile,
      context: '.',
      tags: [
        image.snapshot_tag,
        image.latest_tag
      ]
    })

exports.image_publisher = async (env, { docker, vault }) => {
  const { registry, username, password } = await vault.read(
    `secret/data/docker/${env.platform}`
  )

  return await docker.push({
    tags: images.flatMap(image => [image.snapshot_tag, image.latest_tag]),
    registry,
    credentials: { username, password }
  })
}
