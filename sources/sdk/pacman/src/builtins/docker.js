import { promises as fsPromises } from 'fs'
import Docker from 'dockerode'
import ignore from 'ignore'
import tar from 'tar-fs'

const build_context = async path => {
  let ignore_body

  try {
    const fileHandle = await fsPromises.open(`${path}/.dockerignore`, 'r')
    ignore_body = await fileHandle.readFile({ endoding: 'utf-8' })
  }
  catch (err) {
    ignore_body = ''
  }

  const patterns = ignore_body
    .split('\n')
    .map(p => p.split('#')[0])
    .map(p => p.trim())
    .filter(p => !!p)

  const ig = ignore().add(patterns)

  return tar.pack(path, {
    ignore: name => ig.ignores(name)
  })
}

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
