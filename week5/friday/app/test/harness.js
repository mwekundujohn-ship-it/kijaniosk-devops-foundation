'use strict';

const fs = require('fs');
const path = require('path');

const results = [];

function test(name, fn) {
  try {
    fn();
    results.push({ name: name, ok: true });
    console.log('ok - ' + name);
  } catch (error) {
    results.push({ name: name, ok: false, error: error.message });
    console.error('not ok - ' + name + ': ' + error.message);
  }
}

function escapeXml(value) {
  return String(value).replace(/[&<>"]/g, (char) => {
    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[char];
  });
}

function finish() {
  const outputDir = path.resolve(__dirname, '..', 'test-results');
  fs.mkdirSync(outputDir, { recursive: true });
  const failures = results.filter((result) => !result.ok).length;
  const cases = results.map((result) => {
    const body = result.ok ? '' : '<failure message="' + escapeXml(result.error) + '"/>';
    return '    <testcase name="' + escapeXml(result.name) + '" classname="kijanikiosk-payments">' + body + '</testcase>';
  }).join('\n');
  const xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
    + '<testsuite name="kijanikiosk-payments" tests="' + results.length + '" failures="' + failures + '">\n'
    + cases + '\n</testsuite>\n';
  fs.writeFileSync(path.join(outputDir, 'junit.xml'), xml);
  console.log('');
  console.log((results.length - failures) + ' passed, ' + failures + ' failed');
  if (failures > 0) {
    process.exitCode = 1;
  }
}

module.exports = { test, finish };
