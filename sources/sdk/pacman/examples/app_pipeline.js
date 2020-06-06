exports.make_pipeline = (app_name) => {
  pipeline({
    name: `Build and deploy ${app_name}`,
    tools: [
      'docker',
      'helm',
      'vault',
      'git'
    ],
    environment: async (workspace_pvc, { git }) => ({
      preprod: git.branch() === 'dev',
      prod: git.branch() === 'master',
      name: git.branch() === 'master' ? 'prod' : 'preprod',
      snapshot_tag: `example/app-${env.app_name}:${git.commit().sha}`,
      latest_tag: `example/app-${env.app_name}:latest`
    }),
    stages: [
      {
        name: 'build-docker-image',
        script: async (env, { docker }) => {
          await docker.build({
            dockerfile: `docker/${app_name}.dockerfile`,
            context: '.',
            tags: [
              env.snapshot_tag,
              env.latest_tag
            ]
          })
        }
      },
      {
        name: 'publish-docker-image',
        when: async env => env.preprod || env.prod,
        script: async (env, { docker, vault }) => {
          const { registry, username, password } = await vault.read(
            `secret/data/${app_name}/${env.name}/docker`
          )

          await docker.push({
            registry,
            credentials: { username, password },
            tags: [
              env.snapshot_tag,
              env.latest_tag
            ]
          })
        }
      },
      {
        name: 'deploy-helm-chart',
        when: async (env, { feature_flags }) => {
          const enabled = await feature_flags.get('deployment-authorized')
          return enabled && (env.preprod || env.prod)
        },
        script: async (env, { helm, vault }) => {
          const kubeconfig = await vault.read(`secret/data/${app_name}/${env.name}/kubeconfig`)
          const values = await vault.read(`secret/data/${app_name}/${env.name}/values`)

          await helm.deploy({
            kubeconfig,
            release: {
              name: env.app_name,
              namespace: 'example'
            },
            chart: './chart',
            values
          })
        }
      }
    ]
  })
}
