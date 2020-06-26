const { make_dummy, make_skipped } = include('./examples/stages.js')

pipeline({
  name: 'pipeline-0',
  tools: [],
  environment: async () => ({}),
  stages: [
    make_dummy('dummy'),
    make_skipped('skipped')
  ]
})
