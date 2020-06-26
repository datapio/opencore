pipeline({
  name: 'pipeline-with-docker',
  tools: [
    'docker'
  ],
  environment: async workspace_pvc => ({
    build: workspace_pvc === 'build',
    push: workspace_pvc === 'push'
  }),
  stages: [
    {
      name: 'build',
      when: async env => env.build,
      script: async (env, { docker }) => {
        await docker.build({
          dockerfile: './Dockerfile',
          context: '.',
          tags: [
            'datapio/example:latest'
          ]
        })
      }
    },
    {
      name: 'push',
      when: async env => env.push,
      script: async (env, { docker }) => {
        await docker.push({
          registry: 'http://example.com',
          credentials: { username: 'guest', password: 'guest' },
          tags: [
            'datapio/example:latest'
          ]
        })
      }
    }
  ]
})