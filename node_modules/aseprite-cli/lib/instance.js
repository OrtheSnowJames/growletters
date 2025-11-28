const childProcess = require('child_process');
const os = require('os');

class Instance {
  constructor(customPaths) {
    this._binPath = undefined;

    let options = [];
    let platform = os.platform();
    if (customPaths) {
      options = options.concat(customPaths);
    }
    if (platform === 'darwin') {
      options.push(`/Applications/Aseprite.app/Contents/MacOS/aseprite`);
      options.push(`${process.env.HOME}/Applications/Aseprite.app/Contents/MacOS/aseprite`);
      options.push(`aseprite`);
    } else if (platform === 'win32') {
      options.push(`C:\\Program Files (x86)\\Aseprite\\Aseprite.exe`);
      options.push(`C:\\Program Files\\Aseprite\\Aseprite.exe`);
      options.push(`Aseprite`);
    }

    this._searchPaths = options;
  }

  async exec(...args) {
    const path = await this.binPath();
    return this.raw(path, this.flattenArgs(args));
  }

  execSync(...args) {
    const path = this.binPathSync();
    return this.rawSync(path, this.flattenArgs(args));
  }

  async binPath() {
    if (this._binPath) return this._binPath;

    for (let path of this._searchPaths) {
      try {
        await this.raw(path, '--version');
        this._binPath = path;
        return path;
      } catch (e) { }
    }

    throw new Error('Unable to find Aseprite binary. Searched in: ' + JSON.stringify(this._searchPaths, undefined, 2));
  }

  binPathSync() {
    if (this._binPath) return this._binPath;

    for (let path of this._searchPaths) {
      try {
        this.rawSync(path, '--version');
        this._binPath = path;
        return path;
      } catch (e) { }
    }

    throw new Error('Unable to find Aseprite binary. Searched in: ' + JSON.stringify(this._searchPaths, undefined, 2));
  }

  async raw(path, args) {
    const child = (typeof args === 'string') ?
      childProcess.spawn(`${path} ${args}`, [], { shell: true }) :
      childProcess.spawn(path, args);
    let stdout = undefined, stderr = undefined;

    child.stdout.on('data', data => { stdout = (stdout || '') + data; });
    child.stderr.on('data', data => { stderr = (stderr || '') + data; });

    return new Promise((resolve, reject) => {
      child.addListener('error', (code, signal) => {
        reject(new Error(`Encountered ${code}/${signal}: ${stderr}`));
      });
      child.addListener('exit', (code, signal) => {
        if (code === 0) {
          resolve({
            code: 0,
            stdout,
            stderr
          });
        } else {
          reject(new Error(`Encountered ${code}/${signal}: ${stderr}`));
        }
      });
    });
  }

  rawSync(path, args) {
    const result = (typeof args === 'string') ?
      childProcess.spawnSync(`${path} ${args}`, [], { shell: true }) :
      childProcess.spawnSync(path, args);

    if (result.stdout) result.stdout = result.stdout.toString();
    if (result.stderr) result.stderr = result.stderr.toString();
    return result;
  }

  flattenArgs(args) {
    let source;

    if (args.length === 1) {
      args = args[0];
    } else if (args.length === 2) {
      source = args[0];
      args = args[1];
    } else if (args.length > 2) {
      throw new Error('Invalid arguments: pass (string, array/object/string) or (array/object/string): ' + args);
    }

    if (Array.isArray(args)) {
      if (source) args.unshift(source);
      args.unshift('--batch');
    } else if (typeof args === 'object') {
      args = Object.entries(args).reduce((out, [key, value]) => {
        if (!key.startsWith('--')) {
          key = '--' + key.replace(/([A-Z])/g, (_, char) => `-${char.toLowerCase()}`);
          out.push(`${key}=${value}`);
        }
        return out;
      }, []);
      if (source) args.unshift(source);
      args.unshift('--batch');
    } else {
      args = String(args);
      if (source) args = `${source} ${args}`;
      args = `--batch ${args}`;
    }
    return args;
  }
}

module.exports = Instance;
