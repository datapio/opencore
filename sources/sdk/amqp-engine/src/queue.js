/**
 * Interface to queue related amqplib channel methods.
 *
 * @module queue
 */

/**
 * Abstraction of AMQP queue.
 *
 * @class Queue
 */
class Queue {

  /**
   * Create a new queue from amqplib channel and name.
   * 
   * @param {amqplib.Channel} channel
   * @param {String} name AMQP queue name.
   */
  constructor(channel, name) {
    this.channel = channel
    this.name = name
  }

  /**
   * Check queue existance.
   *
   * @returns {Promise<Boolean>}
   */
  async check() {
    return await this.channel.checkQueue(this.name)
  }

  /**
   * Remove AMQP queue.
   *
   * @param {Object} options See {@link https://www.squaremobius.net/amqp.node/channel_api.html#channel_deleteQueue|amqplib documentation}.
   * @returns {Promise<Boolean>}
   */
  async remove(options) {
    return await this.channel.deleteQueue(this.name, options)
  }

  /**
   * Purge AMQP queue.
   *
   * @returns {Promise<Boolean>}
   */
  async purge() {
    return await this.channel.purgeQueue(this.name)
  }

  /**
   * Bind AMQP source exchange to this AMQP queue.
   *
   * @param {String} source source exchange name.
   * @param {String} pattern routing key.
   * @param {Object} args See {@link https://www.squaremobius.net/amqp.node/channel_api.html#channel_bindQueue|amqplib documentation}.
   * @returns {Promise<Boolean>}
   */
  async bind(source, pattern, args) {
    return await this.channel.bindQueue(this.name, source, pattern, args)
  }

  /**
   * Unbind AMQP source exchange to this AMQP queue.
   *
   * @param {String} source source exchange name.
   * @param {String} pattern routing key.
   * @param {Object} args See {@link https://www.squaremobius.net/amqp.node/channel_api.html#channel_unbindQueue|amqplib documentation}.
   * @returns {Promise<Boolean>}
   */
  async unbind(source, pattern, args) {
    return await this.channel.unbindQueue(this.name, source, pattern, args)
  }
}

module.exports = Queue
