exports.packages = [
  'sources/sdk/k8s-operator',
  'sources/sdk/amqp-engine'
]

exports.package_builder = (env, { tekton }) =>
  async subPath =>
    await tekton.tasks.run('yarn-build', {
      workspaces: [{
        name: 'sources',
        persistentVolumeClaim: {
          claimName: env.workspace_pvc
        },
        subPath
      }]
    })

exports.package_publisher = (env, { tekton, vault }) =>
  async subPath => {
    const { npmrc } = await vault.read(
      `secret/data/npm/${env.platform}`
    )
    const npmrc_file = await fs.open(`./${subPath}/.npmrc`, 'w')

    try {
      await npmrc_file.write(npmrc)
    }
    finally {
      await npmrc_file.close()
    }

    return await tekton.tasks.run('npm-publish', {
      workspaces: [{
        name: 'sources',
        persistentVolumeClaim: {
          claimName: env.workspace_pvc,
        },
        subPath
      }]
    })
  }
