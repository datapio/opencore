/**
 * Delegate cancellable scope cleanup
 * @module cancel-scope
 */

/**
 * Wrapper object for delegated cleanup.
 * @class CancelScope
 */
class CancelScope {
  /**
   * Create a new cancel scope from a callback.
   * @param {Function} cleanup Callback to call on cancel.
   */
  constructor(cleanup) {
    this.cleanup = cleanup
  }

  /**
   * Cancel the scope by calling the cleanup callback.
   */
  cancel() {
    this.cleanup()
  }
}

module.exports = CancelScope
