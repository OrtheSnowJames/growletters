# aseprite-cli

> A simple wrapper for the [Aseprite](https://www.aseprite.org/) CLI.

### Install

```console
npm install aseprite-cli
```

### Usage

To use the Aseprite wrapper, call `Aseprite.exec` and pass any number of strings, arrays, or objects. Strings
and arrays will be added to the command line as-is; object keys will automatically be dasherized (for example,
`sheetType` becomes `--sheet-type`).

```js
const Aseprite = require('aseprite-cli');

await Aseprite.exec('*.aseprite', {
    sheetType: 'packed',
    sheet: 'out.png',
    data: 'out.json'
});
// => Aseprite --batch *.aseprite --sheet-type packed --sheet out.png --data out.json
```

Although objects make option passing look a little nicer, for more control you can format all of the arguments
in the command line yourself.

```js
const Aseprite = require('aseprite-cli');

await Aseprite.exec('*.aseprite', [
    '--sheet-type', 'packed',
    '--sheet', 'out.png',
    '--data', 'out.json'
]);
// => Aseprite --batch *.aseprite --sheet-type packed --sheet out.png --data out.json
```

Replace `exec` with `execSync` to use synchronously.

```js
const Aseprite = require('aseprite-cli');

Aseprite.execSync('*.aseprite', { sheet: 'out.png', sheetType: 'packed' });
// => Aseprite --batch *.aseprite --sheet out.png --sheet-type packed
```

The API returns an object similar to the response of `child_process.spawnSync`, with `code`, `signal`,
`stdout` and `stderr` properties. You can use these to do diagnostics and error-checking.

```js
const Aseprite = require('aseprite-cli');

console.log(Aseprite.execSync('--version').stdout);
```

By default, `aseprite-cli` will automatically find your local installation of Aseprite by searching the
typical install paths for your operating system. If this doesn't work for you, pass in one or more
search paths to check in addition to the normal operating system paths.

```js
// Use the `.instance` function to return an instance with custom search paths
const Aseprite = require('aseprite-cli').instance(['C:\\aseprite\\aseprite.exe', '~/aseprite/aseprite']);

console.log(Aseprite.execSync('--version').stdout);
```

```js
// You can also use syntax sugar 'at'
const Aseprite = require('aseprite-cli').at('/usr/local/aseprite');

console.log(Aseprite.execSync('--version').stdout);
```

### Development

Pull requests welcome.

To run tests locally:

```console
npm install
npm test
```

To try out changes on your own system, open your node console and try running a command:

```console
$ node
> require('.').execSync('--version')
{
  status: 0,
  signal: null,
  output: [
    null,
    <Buffer 41 73 65 70 72 69 74 65 20 31 2e 32 2e 31 38 0a>,
    <Buffer >
  ],
  pid: 29332,
  stdout: 'Aseprite 1.2.18\n',
  stderr: ''
}
>
```

### Disclaimer

This project is not affiliated with or endorsed by the Aseprite team. It uses whatever Aseprite binary
is already installed on your system, and does not include Aseprite or provide additional functionality
beyond what Aseprite already provides.
