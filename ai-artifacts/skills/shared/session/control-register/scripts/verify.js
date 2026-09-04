// Structural check for an control register - the template itself, or any file
// generated from it. Everything asserted here is a failure that renders as a
// plausible-looking page, which is exactly the kind that ships unnoticed.
//
//   npm install jsdom && node verify.js path/to/control-register.html [previous.html]
//
// Given the previous register, it also reports details that have gone missing.
//
// Exits non-zero and lists every failure. Checks that do not apply (no epics,
// no code blocks) are skipped rather than failed. The checks themselves live in
// checks.js; scripts/verify.test.js runs the same ones under node:test.

const fs = require('fs');
const { runAll } = require('./checks');

const file = process.argv[2];
const previousFile = process.argv[3];
if (!file) {
  console.error('usage: node verify.js <register.html> [previous.html]');
  process.exit(2);
}

const result = runAll(
  fs.readFileSync(file, 'utf8'),
  previousFile ? fs.readFileSync(previousFile, 'utf8') : null,
  previousFile
);

if (result.failures.length) {
  console.error(`FAIL  ${result.failures.length} problem(s) in ${file}`);
  result.failures.forEach((f) => console.error('  - ' + f));
  process.exit(1);
}
console.log(`PASS  ${result.itemCount} rows, ${result.epicCount} epic header(s), ${result.codeBlockCount} code block(s)`);
