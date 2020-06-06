const platforms = include('.datapio/platofrms.js')
const npm  = include('.datapio/npm.js')
const docker = include('.datapio/docker.js')
const helm = include('.datapio/helm.js')

pipeline({
  name: 'deploy-continuous-integration',
  tools: [
    'docker',
    'helm',
    'git',
    'vault',
    'tekton'
  ],
  environment: async (workspace_pvc, { git }) => ({
    workspace_pvc,
    packages: npm.packages,
    images: docker.images(git.commit().sha),
    charts: helm.charts(git.commit().sha),
    platform: platforms[git.branch()] || null
  }),
  stages: [
    {
      name: 'build-npm-packages',
      script: async (env, tools) => {
        await parallelMap(env.packages, npm.package_builder(env, tools))
      }
    },
    {
      name: 'publish-npm-packages',
      when: async env => env.platform !== null,
      script: async (env, tools) => {
        await parallelMap(env.packages, npm.package_publisher(env, tools))
      }
    },
    {
      name: 'build-docker-images',
      script: async (env, tools) => {
        await parallelMap(env.images, docker.image_builder(env, tools))
      }
    },
    {
      name: 'push-docker-images',
      when: async env => env.platform !== null,
      script: async (env, tools) => {
        await docker.image_publisher(env, tools)
      }
    },
    {
      name: 'deploy-helm-charts',
      when: async env => env.platform !== null,
      script: async (env, tools) => {
        await helm.chart_deployer(env, tools)
      }
    }
  ]
})
