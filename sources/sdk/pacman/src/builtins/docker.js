const { promises: fsPromises } = require('fs')
const Docker = require('dockerode')
const ignore = require('ignore')
const tar = require('tar-fs')

const build_context = async path => {
  let ignore_body = ''

  try {
    const fileHandle = await fsPromises.open(`${path}/.dockerignore`, 'r')
    ignore_body = await fileHandle.readFile({ endoding: 'utf-8' })
  }
  catch (err) {
    console.error('No .dockerignore found in context')
    console.debug(err)
  }

  const patterns = ignore_body
    .split('\n')
    .map(pattern => pattern.split('#')[0])
    .map(pattern => pattern.trim())
    .filter(pattern => Boolean(pattern))

  const ig = ignore().add(patterns)

  return tar.pack(path, {
    ignore: name => ig.ignores(name)
  })
}

module.exports = async () => {
  const client = new Docker({ socketPath: '/var/run/docker.sock' })

  return {
    requires: [],
    interface: () => ({
      client,
      build: async ({ context, dockerfile, buildargs, tags }) => {
        return await client.buildImage(
          {
            context,
            src: await build_context(context)
          },
          {
            dockerfile,
            buildargs,
            t: tags // eslint-disable-line id-length
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
