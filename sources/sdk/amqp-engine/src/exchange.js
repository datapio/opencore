class Exchange {
  constructor(channel, name) {
    this.channel = channel
    this.name = name
  }

  async check() {
    return await this.channel.checkExchange(this.name)
  }

  async remove(options) {
    return await this.channel.deleteExchange(this.name, options)
  }

  async bind(source, pattern, args) {
    return await this.channel.bindExchange(this.name, source, pattern, args)
  }

  async unbind(source, pattern, args) {
    return await this.channel.unbindExchange(this.name, source, pattern, args)
  }
}

module.exports = Exchange
