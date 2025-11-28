const Instance = require('./lib/instance');
const defaultInstance = new Instance();

module.exports = {
  async exec(...args) {
    return defaultInstance.exec(...args);
  },

  execSync(...args) {
    return defaultInstance.execSync(...args);
  },

  instance(paths) {
    return new Instance(paths);
  },

  at(paths) {
    return new Instance(paths);
  }
};
