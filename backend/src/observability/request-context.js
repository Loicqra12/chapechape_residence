const { AsyncLocalStorage } = require('async_hooks');

const storage = new AsyncLocalStorage();

function runWithRequestContext(ctx, fn) {
  return storage.run(ctx, fn);
}

function getRequestContext() {
  return storage.getStore() || null;
}

module.exports = {
  runWithRequestContext,
  getRequestContext,
};
