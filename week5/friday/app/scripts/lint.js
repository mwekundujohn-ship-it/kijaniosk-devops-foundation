'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const sourceRoot = path.resolve(__dirname, '..', 'src');
const files = [];

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
    } else if (full.endsWith('.js')) {
      files.push(full);
    }
  }
}

walk(sourceRoot);

let problems = 0;

for (const file of files) {
  try {
    execFileSync(process.execPath, ['--check', file], { stdio: 'pipe' });
  } catch (error) {
    problems += 1;
    console.error('Syntax error in ' + file);
    console.error(String(error.stderr || ''));
  }

  const text = fs.readFileSync(file, 'utf8');
  text.split('\n').forEach((line, index) => {
    const where = file + ':' + (index + 1);
    if (line.includes('\t')) {
      problems += 1;
      console.error(where + ': tab character');
    }
    if (/[ \t]+$/.test(line)) {
      problems += 1;
      console.error(where + ': trailing whitespace');
    }
    if (line.length > 120) {
      problems += 1;
      console.error(where + ': line longer than 120 characters');
    }
  });
}

if (problems > 0) {
  console.error('Lint failed with ' + problems + ' problem(s)');
  process.exit(1);
}

console.log('Lint passed: ' + files.length + ' source file(s) checked');
