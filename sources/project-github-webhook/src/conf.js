/* eslint no-sync: "error"*/
import { readFileSync } from 'fs'
import yaml from 'yaml'

const readConf = (path) => {
    const stream = readFileSync(path, 'utf8')
    return yaml.safeLoad(stream)
}

export default readConf('config.yml')
