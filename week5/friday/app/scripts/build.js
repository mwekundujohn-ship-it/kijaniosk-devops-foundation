'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const appRoot = path.resolve(__dirname, '..');
const sourceRoot = path.join(appRoot, 'src');
const distRoot = path.join(appRoot, 'dist');
const pkg = require(path.join(appRoot, 'package.json'));

fs.rmSync(distRoot, { recursive: true, force: true });
fs.mkdirSync(distRoot, { recursive: true });
fs.cpSync(sourceRoot, distRoot, { recursive: true });

let commit = 'unknown';
try {
  commit = execFileSync('git', ['rev-parse', '--short', 'HEAD'], { encoding: 'utf8' }).trim();
} catch (error) {
  console.warn('Could not read git commit: ' + error.message);
}

const buildInfo = {
  name: pkg.name,
  version: pkg.version,
  commit: commit,
  builtAt: new Date().toISOString()
};

fs.writeFileSync(
  path.join(distRoot, 'build-info.json'),
  JSON.stringify(buildInfo, null, 2) + '\n'
);

console.log('Built ' + pkg.name + ' ' + pkg.version + ' (' + commit + ') into dist/');
