import fs from 'fs'
import yaml from 'yaml'

const readConf = path => {
  let result
  try {
    result = yaml.safeLoad(fs.readFileSync(path, 'utf8'));
  } catch (e) {
    console.log(e);
  }
  return result
}

export default readConf('config.yml')
