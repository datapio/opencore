import Docker from 'dockerode'

export default async () => {
  const client = new Docker({ socketPath: '/var/run/docker.sock' })

  return {
    requires: [],
    interface: () => ({
      client,
      build: async ({ context, dockerfile, buildargs, tags }) => {
        return await client.buildImage(
          {
            context,
            src: await build_context(context),
          },
          {
            dockerfile,
            buildargs,
            t: tags
          }
        )
      },
      push: async ({ tags, registry, credentials: { username, password } }) => {
        return await Promise.all(tags.map(async name => {
          const image = await client.getImage(name)
          const [repo, tag] = name.split(':')
          await image.tag({ repo: `${registry}/${repo}`, tag })

          return await image.push({
            tag: name,
            authconfig: {
              username,
              password,
              serveraddress: repo
            }
          })
        }))
      }
    })
  }
}
