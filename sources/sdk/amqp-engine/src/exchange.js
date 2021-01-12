/**
 * Interface to exchange related amqplib channel methods.
 * 
 * @module exchange
 */

/**
 * Abstraction of AMQP exchange.
 * 
 * @class Exchange
 */
class Exchange {
  /**
   * Create a new exchange from amqplib channel and name.
   * 
   * @param {amqplib.Channel} channel
   * @param {String} name AMQP exchange name.
   */
  constructor(channel, name) {
    this.channel = channel
    this.name = name
  }

  /**
   * Check exchange existance.
   * @returns {Promise<Boolean>}
   */
  async check() {
    return await this.channel.checkExchange(this.name)
  }

  /**
   * Remove AMQP exchange.
   * 
   * @param {Object} options See {@link https://www.squaremobius.net/amqp.node/channel_api.html#channel_deleteExchange|amqplib documentation}.
   * @returns {Promise<Boolean>}
   */
  async remove(options) {
    return await this.channel.deleteExchange(this.name, options)
  }

  /**
   * Bind AMQP source exchange to this AMQP exchange.
   * 
   * @param {String} source source exchange name.
   * @param {String} pattern routing key.
   * @param {Object} args See {@link https://www.squaremobius.net/amqp.node/channel_api.html#channel_bindExchange|amqplib documentation}.
   * @returns {Promise<Boolean>}
   */
  async bind(source, pattern, args) {
    return await this.channel.bindExchange(this.name, source, pattern, args)
  }

  /**
   * Unbind AMQP source exchange to this AMQP exchange.
   * 
   * @param {String} source source exchange name.
   * @param {String} pattern routing key
   * @param {Object} args See {@link https://www.squaremobius.net/amqp.node/channel_api.html#channel_unbindExchange|amqplib documentation}.
   * @returns {Promise<Boolean>}
   */
  async unbind(source, pattern, args) {
    return await this.channel.unbindExchange(this.name, source, pattern, args)
  }
}

module.exports = Exchange
