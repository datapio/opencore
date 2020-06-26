exports.make_dummy = name => ({
  name,
  when: async () => true,
  script: async () => {}
})

exports.make_skipped = name => ({
  name,
  when: async () => false,
  script: async () => {}
})
