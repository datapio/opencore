exports.charts = sha => [
  {
    path: './charts/pipelinerunserver-operator',
    release: {
      name: 'pipelinerunserver-operator',
      namespace: 'datapio'
    },
    values: {
      image: {
        name: 'datapio/pipelinerunserver-operator',
        tag: sha,
        pullPolicy: 'IfNotPresent'
      }
    }
  },
  {
    path: './charts/project-operator',
    release: {
      name: 'project-operator',
      namespace: 'datapio'
    },
    values: {
      image: {
        name: 'datapio/project-operator',
        tag: sha,
        pullPolicy: 'IfNotPresent'
      }
    }
  }
]

exports.chart_deployer = async (env, { helm, vault }) => {
  const { kubeconfig } = await vault.read(
    `secret/data/k8s/${env.platform}`
  )

  return await sequentialMap(env.charts, async chart => {
    return await helm.deploy({
      kubeconfig,
      chart: chart.path,
      release: chart.release,
      values: chart.values
    })
  })
}
