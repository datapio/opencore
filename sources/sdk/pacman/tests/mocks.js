const mock = require('mock-require')
const sinon = require('sinon')

const spies = {
  dockerode: sinon.spy(),
  docker_image: sinon.spy()
}

spies.dockerode.prototype.buildImage = sinon.spy()
spies.dockerode.prototype.getImage = sinon.stub().callsFake(async () => spies.docker_image)
spies.docker_image.tag = sinon.stub().callsFake(async () => {})
spies.docker_image.push = sinon.stub().callsFake(async () => {})

for (let key of Object.keys(spies)) {
  mock(key, spies[key])
}

module.exports = spies
