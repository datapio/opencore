class CancelScope {
  constructor(cleanup) {
    this.cleanup = cleanup
  }

  cancel() {
    this.cleanup()
  }
}

module.exports = CancelScope
