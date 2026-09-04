// Edit a control register without re-authoring it.
//
//   node scripts/register.js <file> add    --action decide --item "..." --rec "..." --why "..."
//   node scripts/register.js <file> close  58 73 --mark ok
//   node scripts/register.js <file> edit   84 --rec "..." --why "..."
//   node scripts/register.js <file> block  84 --by 78
//   node scripts/register.js <file> block  84 --clear
//   node scripts/register.js <file> promote 88 [--to docs/adr/0007-x.md]
//   node scripts/register.js <file> archive          -> control-register-closed.md
//   node scripts/register.js <file> check  [previous.html]
//
// Every mutating command writes, then runs the checks. A command that leaves
// the register failing restores the file and reports - a register that is wrong
// is worse than one that is unchanged, because it still looks current.
//
// Rows are built here, so a new row cannot have the wrong shape. The checks
// stay as regression tests: they cover the rows this file did not write.

const fs = require('fs');
const path = require('path');
const { runAll, FALLBACK_CONTRACT, CLOSED_KEPT } = require('./checks');

const ACTIONS = Object.keys(FALLBACK_CONTRACT.RANK);
const MARKS = { ok: '✅', superseded: '↩️' };
const STATUS_CLASS = { ok: 'resolved', superseded: 'superseded' };

// ---- reading -------------------------------------------------------------

const escape = (text) => String(text)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;').replace(/'/g, '&apos;');

// A closed row carries data-closed between the class and the first cell, so the
// pattern has to allow attributes there. Without `[^>]*` it silently matches
// open rows only, and archiving becomes a no-op that reports success.
const rowPattern = (id) =>
  new RegExp(`<tr class="[^"]*"[^>]*><td class="id">${id}</td>[\\s\\S]*?</tr>\\n`);

const detailPattern = (id) =>
  new RegExp(`(<tr class="[^"]*"[^>]*><td class="id">${id}</td>[\\s\\S]*?</tr>\\n)(<tr class="detail" hidden>[\\s\\S]*?</tr>\\n)?`);

function rowOf(src, id) {
  const match = src.match(rowPattern(id));
  if (!match) { throw new Error(`#${id} is not in this register`); }
  return match[0];
}

function idsIn(src) {
  return Array.from(src.matchAll(/<td class="id">(\d+)<\/td>/g), (m) => Number(m[1]));
}

function closedIndicesIn(src) {
  return Array.from(src.matchAll(/data-closed="(\d+)"/g), (m) => Number(m[1]));
}

function actionOf(row) {
  const classes = (row.match(/<tr class="([^"]*)"/) || [, ''])[1].split(' ');
  return ACTIONS.find((a) => classes.includes(a));
}

const isClosed = (row) => /class="[^"]*(?:resolved|superseded)/.test(row);

// ---- commands ------------------------------------------------------------

function add(src, opts) {
  if (!ACTIONS.includes(opts.action)) {
    throw new Error(`--action must be one of ${ACTIONS.join(', ')}`);
  }
  ['item', 'rec', 'why'].forEach((k) => {
    if (!opts[k]) { throw new Error(`--${k} is required`); }
  });
  const id = opts.id ? Number(opts.id) : Math.max(0, ...idsIn(src)) + 1;
  if (idsIn(src).includes(id)) { throw new Error(`#${id} already exists - IDs are never reused`); }

  const detail = opts.detail ? fs.readFileSync(opts.detail, 'utf8').trim() : null;
  const classes = ['tr-open', opts.action, detail ? 'has-detail' : ''].filter(Boolean);
  const blocked = opts.blockedBy
    ? `<span class="blocked">blocked by <button type="button" class="jump" data-goto="${opts.blockedBy}">#${opts.blockedBy}</button></span>`
    : '';
  let row = `<tr class="${classes.join(' ').replace('tr-open ', '')}"><td class="id">${id}</td>`
    + `<td>${escape(opts.item)}</td>`
    + `<td class="act">${opts.action}${blocked}</td>`
    + `<td>${escape(opts.rec)}</td><td>${escape(opts.why)}</td></tr>\n`;
  if (detail) { row += `<tr class="detail" hidden><td colspan="5">\n${detail}\n</td></tr>\n`; }
  return { src: src.replace('<tbody>\n', `<tbody>\n\n${row}`), id };
}

// A batch closes together, so the batch gets contiguous indices in action-rank
// then ID order. Without the ordering two rows closed in the same breath would
// be arbitrarily older than one another.
function close(src, ids, opts) {
  const rows = ids.map((id) => ({ id, row: rowOf(src, id) }));
  rows.forEach(({ id, row }) => {
    if (isClosed(row)) { throw new Error(`#${id} is already closed`); }
  });
  rows.sort((a, b) =>
    ACTIONS.indexOf(actionOf(a.row)) - ACTIONS.indexOf(actionOf(b.row)) || a.id - b.id);

  let next = Math.max(0, ...closedIndicesIn(src)) + 1;
  const mark = MARKS[opts.mark || 'ok'];
  const statusClass = STATUS_CLASS[opts.mark || 'ok'];

  rows.forEach(({ id, row }) => {
    let updated = row
      .replace(/^<tr class="([^"]*)"/, `<tr class="$1 ${statusClass}" data-closed="${next}"`)
      .replace(/(<td class="act">[a-z]+)(<span class="blocked">[\s\S]*?<\/span>)?/,
        `$1<span class="mark">${mark}</span>`);
    if (opts.rec) {
      updated = updated.replace(/(<td class="act">[\s\S]*?<\/td>)<td>[\s\S]*?<\/td>(<td>)/,
        `$1<td>${escape(opts.rec)}</td>$2`);
    }
    if (opts.why) {
      updated = updated.replace(/<td>((?:(?!<td>)[\s\S])*?)<\/td><\/tr>/, `<td>${escape(opts.why)}</td></tr>`);
    }
    src = src.replace(row, updated);
    next++;
  });
  return src;
}

// A minor revision: same question, same thing to act on. The row keeps its ID
// and gains no marker, because the file is the current state.
function edit(src, id, opts) {
  const row = rowOf(src, id);
  if (!opts.item && !opts.rec && !opts.why) {
    throw new Error('edit needs --item, --rec or --why');
  }
  let updated = row;
  if (opts.item) {
    updated = updated.replace(/(<td class="id">\d+<\/td><td>)[\s\S]*?(<\/td>)/,
      `$1${escape(opts.item)}$2`);
  }
  if (opts.rec) {
    updated = updated.replace(/(<td class="act">[\s\S]*?<\/td>)<td>[\s\S]*?<\/td>(<td>)/,
      `$1<td>${escape(opts.rec)}</td>$2`);
  }
  if (opts.why) {
    updated = updated.replace(/<td>((?:(?!<td>)[\s\S])*?)<\/td><\/tr>/, `<td>${escape(opts.why)}</td></tr>`);
  }
  return src.replace(row, updated);
}

function block(src, id, opts) {
  const row = rowOf(src, id);
  const stripped = row.replace(/<span class="blocked">[\s\S]*?<\/span>/, '');
  if (opts.clear) { return src.replace(row, stripped); }
  if (!opts.by) { throw new Error('block needs --by <id> or --clear'); }
  if (!idsIn(src).includes(Number(opts.by))) {
    throw new Error(`#${opts.by} is not in this register`);
  }
  const marker = `<span class="blocked">blocked by <button type="button" class="jump" data-goto="${opts.by}">#${opts.by}</button></span>`;
  return src.replace(row, stripped.replace(/(<td class="act">[a-z]+)/, `$1${marker}`));
}

// Moving a closed row out is an append at one end of the archive, not a rewrite
// of it - which is the whole reason the archive can grow without cost.
function archive(src, opts) {
  const keep = Number(opts.keep || CLOSED_KEPT);
  // Beside the register by default: the archive is that session's overflow, not
  // a shared one, so it belongs in the same folder. Named in full rather than
  // `closed.md` because it leaves the folder - handed to another session, it
  // has to say what it is the closed rows of.
  const target = opts.to || path.join(path.dirname(file), 'control-register-closed.md');
  const closed = Array.from(src.matchAll(/<tr class="[^"]*(?:resolved|superseded)[^"]*"[^>]*data-closed="(\d+)"[\s\S]*?<\/tr>\n/g))
    .map((m) => ({ index: Number(m[1]), row: m[0] }));
  const doomed = closed.sort((a, b) => b.index - a.index).slice(keep);
  if (!doomed.length) { return { src, moved: 0, target }; }

  // A section per row rather than a table row, because the detail has to come
  // with it. Archiving the row and dropping its reasoning would destroy the
  // thing the archive exists to keep.
  const lines = doomed.sort((a, b) => a.index - b.index).map(({ index, row }) => {
    const cells = Array.from(row.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g), (m) => plain(m[1]));
    const [id, item, act, rec, why] = cells;
    const detailMatch = src.match(detailPattern(id));
    const detail = detailMatch && detailMatch[2] ? markdownise(detailMatch[2]) : '';
    return `## #${id} — ${act}\n\n*closed ${index}*\n\n**${item}**\n\n`
      + `- Recommendation: ${rec}\n- Rationale: ${why}\n${detail}`;
  });
  const header = fs.existsSync(target) ? '' :
    '# Closed rows\n\nMoved out of the live register once past the newest '
    + `${keep}. Append-only: nothing here is ever rewritten.\n`;
  fs.appendFileSync(target, header + lines.join('\n') + '\n');

  doomed.forEach(({ row }) => {
    const id = (row.match(/<td class="id">(\d+)<\/td>/) || [])[1];
    src = src.replace(detailPattern(id), '');
  });
  return { src, moved: doomed.length, target };
}

// Enough of the detail markup to stay readable: headings become headings, code
// blocks stay fenced, everything else becomes a paragraph.
function markdownise(detail) {
  const body = (detail.match(/<td colspan="\d+">([\s\S]*?)<\/td>/) || [, ''])[1];
  return '\n' + body
    .replace(/<h3>([\s\S]*?)<\/h3>/g, (m, t) => `\n### ${plain(t)}\n`)
    .replace(/<pre><code>([\s\S]*?)<\/code><\/pre>/g, (m, c) => '\n```\n' + plain(c) + '\n```\n')
    .replace(/<\/?(p|ul|li|em|strong|code|button|span)[^>]*>/g, '')
    .replace(/\n{3,}/g, '\n\n') + '\n';
}

const plain = (html) => html
  .replace(/<[^>]+>/g, '')
  .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&quot;/g, '"').replace(/&apos;/g, "'")
  .replace(/\|/g, '\\|').replace(/\s+/g, ' ').trim();

// Promotion is the opposite of archiving: archiving is automatic and disposable,
// promotion is chosen and committed. Most closed rows are neither evidence nor
// decisions, so nothing here happens on its own.
//
// The output is a draft. `Rule` and `Problem` are seeded from the row, the rest
// is the detail dropped in below for cutting down - a four-part entry cannot be
// derived mechanically from a row, and pretending otherwise would fill the file
// with entries nobody wrote.
const SHAPES = {
  adr: (item, rec, why, detail) =>
    `# ${item}\n\n## Status\n\nAccepted\n\n## Context\n\n${why}\n\n`
    + `## Decision\n\n${rec}\n\n## Consequences\n\nTODO\n${detail}`
};

function promote(src, ids, opts) {
  const target = opts.to || 'DECISIONS.md';
  const shape = opts.shape || 'adr';
  if (!SHAPES[shape]) {
    throw new Error(`--shape must be one of ${Object.keys(SHAPES).join(', ')}`);
  }
  const sections = ids.map((id) => {
    const row = rowOf(src, id);
    const cells = Array.from(row.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g), (m) => plain(m[1]));
    const [, item, , rec, why] = cells;
    const detailMatch = src.match(detailPattern(id));
    const detail = detailMatch && detailMatch[2] ? markdownise(detailMatch[2]) : '';
    return SHAPES[shape](item, rec, why, detail);
  });
  const header = fs.existsSync(target) ? '' :
    `# Decisions\n\nPromoted from the control register. Each entry is here because it was\nchosen to be, not because a row closed.\n`;
  fs.appendFileSync(target, header + '\n' + sections.join('\n'));
  return { moved: ids.length, target };
}

// ---- entry point ---------------------------------------------------------

function parseArgs(argv) {
  const opts = {}, rest = [];
  for (let i = 0; i < argv.length; i++) {
    if (!argv[i].startsWith('--')) { rest.push(argv[i]); continue; }
    const key = argv[i].slice(2).replace(/-([a-z])/g, (m, c) => c.toUpperCase());
    const value = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : true;
    opts[key] = value;
  }
  return { opts, rest };
}

const [file, command, ...argv] = process.argv.slice(2);
if (!file || !command) {
  console.error('usage: node register.js <file> add|edit|close|block|promote|archive|check [...]');
  process.exit(2);
}
const { opts, rest } = parseArgs(argv);
const before = fs.readFileSync(file, 'utf8');
let after = before, note = '';

try {
  if (command === 'add') {
    const result = add(before, opts);
    after = result.src;
    note = `added #${result.id}`;
  } else if (command === 'close') {
    if (!rest.length) { throw new Error('close needs at least one ID'); }
    after = close(before, rest.map(Number), opts);
    note = `closed ${rest.map((id) => '#' + id).join(' ')}`;
  } else if (command === 'edit') {
    after = edit(before, Number(rest[0]), opts);
    note = `edited #${rest[0]}`;
  } else if (command === 'block') {
    after = block(before, Number(rest[0]), opts);
    note = opts.clear ? `cleared the blocker on #${rest[0]}` : `#${rest[0]} blocked by #${opts.by}`;
  } else if (command === 'promote') {
    if (!rest.length) { throw new Error('promote needs at least one ID'); }
    const result = promote(before, rest.map(Number), opts);
    note = `drafted ${result.moved} entr(y|ies) in ${result.target} - edit before committing`;
  } else if (command === 'archive') {
    const result = archive(before, opts);
    after = result.src;
    note = `moved ${result.moved} row(s) to ${result.target}`;
  } else if (command !== 'check') {
    throw new Error(`unknown command "${command}"`);
  }
} catch (error) {
  console.error(`register: ${error.message}`);
  process.exit(1);
}

if (after !== before) { fs.writeFileSync(file, after); }

const previous = rest.find((a) => a.endsWith('.html')) || opts.previous;
const result = runAll(fs.readFileSync(file, 'utf8'),
  previous ? fs.readFileSync(previous, 'utf8') : null, previous);

if (result.failures.length) {
  if (after !== before) { fs.writeFileSync(file, before); }
  console.error(`register: ${note || 'check'} left ${result.failures.length} problem(s)`
    + (after !== before ? ' - the file is unchanged' : ''));
  result.failures.forEach((f) => console.error('  - ' + f));
  process.exit(1);
}
console.log(`${note ? note + '; ' : ''}PASS  ${result.itemCount} rows, `
  + `${result.epicCount} epic header(s), ${result.codeBlockCount} code block(s)`);
