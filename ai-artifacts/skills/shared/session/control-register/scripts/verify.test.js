// The same checks as verify.js, one named test each, every test on its own DOM.
//
//   npm install jsdom && node --test scripts/verify.test.js
//
// REGISTER=path/to/file.html selects what to check; the template is the default
// because it is the one file that must always pass.

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const checks = require('./checks');
const { mutations, unmutated } = require('../tests/mutations');

const registerPath = process.env.REGISTER
  || path.join(__dirname, '..', 'assets', 'template.html');
const src = fs.readFileSync(registerPath, 'utf8');

const report = (failures) => assert.deepStrictEqual(failures, [],
  '\n  - ' + failures.join('\n  - '));

test(`checking ${path.basename(registerPath)}`, async (t) => {
  const live = checks.liveContext(src);
  const inert = checks.inertContext(src);
  inert.contract = live.contract;

  for (const [name, check] of Object.entries(checks.readOnlyChecks)) {
    await t.test(name, () => report(check(live)));
  }
  for (const [name, check] of Object.entries(checks.readOnlyChecksNeedingInert)) {
    await t.test(name, () => report(check(live, inert)));
  }
  // A fresh parse per interactive check. Sharing one is what made the old
  // verifier order-dependent, and what made a default state look like a bug.
  for (const [name, check] of Object.entries(checks.interactiveChecks)) {
    await t.test(name, () => report(check(checks.freshContext(src), inert)));
  }

  // Every check must be shown to fail. A check that cannot be made to fail is
  // not evidence: a broken selector returns no failures, which reads as pass.
  const allChecks = Object.assign({}, checks.readOnlyChecks,
    checks.readOnlyChecksNeedingInert, checks.interactiveChecks, checks.differentialChecks);

  await t.test('every check is either mutated or listed as unmutated', () => {
    const covered = new Set(Object.keys(mutations).concat(Object.keys(unmutated)));
    const missing = Object.keys(allChecks).filter((name) => !covered.has(name));
    assert.deepStrictEqual(missing, [],
      'add a mutation in tests/mutations.js, or a reason in its unmutated list');
  });

  for (const [name, mutate] of Object.entries(mutations)) {
    await t.test(`${name} rejects a broken register`, () => {
      const broken = mutate(src);
      if (broken === null || broken === src) {
        t.diagnostic(`${name}: this register cannot carry the mutation`);
        return;
      }
      const brokenLive = checks.liveContext(broken);
      const brokenInert = checks.inertContext(broken);
      brokenInert.contract = brokenLive.contract;
      const failures = checks.differentialChecks[name]
        ? checks.differentialChecks[name](brokenInert, inert, 'the unmutated register')
        : allChecks[name](brokenLive, brokenInert);
      assert.ok(failures.length > 0, `${name} passed a register mutated to break it`);
    });
  }

  // Differential checks need the register from the turn before this one.
  const previousPath = process.env.PREVIOUS;
  const previous = previousPath
    ? checks.inertContext(fs.readFileSync(previousPath, 'utf8')) : null;
  for (const [name, check] of Object.entries(checks.differentialChecks)) {
    await t.test(name, { skip: previous ? false : 'set PREVIOUS to the earlier register' },
      () => report(check(inert, previous, previousPath)));
  }
});
