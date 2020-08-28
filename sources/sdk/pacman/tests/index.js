const stubs = require('./stubs.js')

const { execute_manifest } = require('../src/sandbox.js')
const { expect } = require('chai')
const sinon = require('sinon')

describe('sandbox', () => {
  beforeEach(stubs.before)
  afterEach(stubs.after)

  it('should run the dummy example', async function () {
    const result = await execute_manifest(null, './examples/dummy.js')

    expect(this.records[0].manifest).to.be.a('string')
    expect(this.records[0].manifest).to.equal('./examples/dummy.js')

    expect(this.records[1].manifest).to.be.a('string')
    expect(this.records[1].manifest).to.equal('./examples/stages.js')

    const started_pipelines = this.records.filter(r => r.event === 'started' && !r.stage)
    expect(started_pipelines, 'started_pipelines').to.have.lengthOf(1)

    const started_dummy_stages = this.records.filter(r => r.event === 'started' && r.stage === 'dummy')
    expect(started_dummy_stages, 'started_dummy_stages').to.have.lengthOf(1)

    const succeeded_dummy_stages = this.records.filter(r => r.event === 'succeeded' && r.stage === 'dummy')
    expect(succeeded_dummy_stages, 'succeeded_dummy_stages').to.have.lengthOf(1)

    const started_skipped_stages = this.records.filter(r => r.event === 'started' && r.stage === 'skipped')
    expect(started_skipped_stages, 'started_skipped_stages').to.have.lengthOf(0)

    const skipped_stages = this.records.filter(r => r.event === 'skipped' && r.stage === 'skipped')
    expect(skipped_stages, 'skipped_stages').to.have.lengthOf(1)

    const succeeded_pipelines = this.records.filter(r => r.event === 'succeeded' && !r.stage)
    expect(succeeded_pipelines, 'succeeded_pipelines').to.have.lengthOf(1)

    expect(result.every(x => x)).to.be.true
  })
})

describe('plugins', () => {
  describe('docker', () => {
    beforeEach(stubs.before)
    afterEach(stubs.after)

    it('should build a docker image', async () => {
      const result = await execute_manifest('build', './examples/docker.js')
      const Docker = require('dockerode')

      sinon.assert.calledOnce(Docker)
      sinon.assert.calledOnce(Docker.prototype.buildImage)

      expect(result.every(x => x)).to.be.true
    })

    it('should push a docker image', async () => {
      const result = await execute_manifest('push', './examples/docker.js')
      const Docker = require('dockerode')

      sinon.assert.calledOnce(Docker)
      sinon.assert.calledOnce(Docker.prototype.getImage)
      const image = await Docker.prototype.getImage()
      sinon.assert.calledOnce(image.tag)
      sinon.assert.calledOnce(image.push)

      expect(result.every(x => x)).to.be.true
    })
  })
})
