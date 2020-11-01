class Queue {
  constructor(channel, name) {
    this.channel = channel
    this.name = name
  }

  async check() {
    return await this.channel.checkQueue(this.name)
  }

  async remove(options) {
    return await this.channel.deleteQueue(this.name, options)
  }

  async purge() {
    return await this.channel.purgeQueue(this.name)
  }

  async bind(source, pattern, args) {
    return await this.channel.bindQueue(this.name, source, pattern, args)
  }

  async unbind(source, pattern, args) {
    return await this.channel.unbindQueue(this.name, source, pattern, args)
  }
}

module.exports = Queue
