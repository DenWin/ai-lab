// The structural checks for an control register, as one named function each.
//
// Every check takes a context and returns the failures it found. Nothing here
// prints, exits, or reads argv - scripts/verify.js does that for a one-shot
// run, scripts/verify.test.js does it per test.
//
// Three kinds of context, because the cost and the coupling differ:
//
//   inertContext   parsed without scripts. Reports what was authored.
//   liveContext    parsed with scripts, shared by checks that only read.
//   freshContext   parsed with scripts, one per check that presses the page.
//
// The split is the point. A check that clicks a chip changes what every later
// check sees, and the old single-DOM verifier made that coupling load-bearing:
// its epic section had to undo its own clicks, and one bug in this file was a
// default state reported as a collapse failure.

const { JSDOM } = require('jsdom');

// The template publishes its own vocabulary on window.__cb. Reading it here
// means a new action or a new verdict button is one edit, not two - and a
// missed second edit used to make the verifier blame the register for a stale
// constant in this file. TPL is the exception and stays: its whole job is to
// disagree with the template.
const TPL = '11';
const CLOSED_KEPT = 15;
const FALLBACK_CONTRACT = {
  RANK: { decide: 0, paste: 1, exec: 2, review: 3, agent: 4, ack: 5 },
  STATUS: ['resolved', 'superseded'],
  VERDICTS: {}
};

const actionsOf = (ctx) => Object.keys((ctx.contract || FALLBACK_CONTRACT).RANK);
const statusesOf = (ctx) => (ctx.contract || FALLBACK_CONTRACT).STATUS;
const verdictCountOf = (ctx) => {
  const verdicts = (ctx.contract || FALLBACK_CONTRACT).VERDICTS;
  return Object.fromEntries(Object.entries(verdicts).map(([k, v]) => [k, v.length]));
};

// A row's choices replace its action's verdict pair, so the expected button
// count is per row, not per action. The separator is duplicated from the
// template deliberately: it is one character of grammar, not a constant whose
// drift the verifier could not see.
const choicesOf = (row) => {
  const raw = row.dataset.choices;
  return raw ? raw.split('|').map((choice) => choice.trim()) : null;
};

const verdictCountFor = (row, counts) => {
  const choices = choicesOf(row);
  return choices ? choices.length : (counts[row.dataset.action] || 0);
};

// --- contexts -----------------------------------------------------------

function inertContext(src) {
  const doc = new JSDOM(src).window.document;
  return withQueries({ doc, live: false });
}

function liveContext(src) {
  const dom = new JSDOM(src, { runScripts: 'dangerously', pretendToBeVisual: true });
  return withQueries({ doc: dom.window.document, win: dom.window, live: true });
}

const freshContext = liveContext;

function withQueries(ctx) {
  const doc = ctx.doc;
  ctx.contract = ctx.win && ctx.win.__cb ? ctx.win.__cb : null;
  ctx.rowsOf = () => Array.from(doc.querySelector('tbody').rows);
  ctx.epicHeaders = () => ctx.rowsOf().filter((r) => r.classList.contains('epichead'));
  ctx.items = () => ctx.rowsOf().filter((r) => !r.classList.contains('epichead')
    && !r.classList.contains('blockend') && !r.classList.contains('detail'));
  ctx.visibleRows = () => ctx.rowsOf().filter((r) => !r.hidden);
  ctx.columnCount = doc.querySelector('thead tr').cells.length;
  ctx.itemIds = () => new Set(ctx.items().map((r) => r.cells[0].textContent.trim()));
  ctx.chip = (key) => Array.from(doc.querySelectorAll('.chip'))
    .find((c) => c.dataset.key === key);
  if (ctx.win) { ctx.click = (el) => el.dispatchEvent(new ctx.win.Event('click')); }
  return ctx;
}

function collector() {
  const failures = [];
  const assert = (condition, message) => { if (!condition) { failures.push(message); } };
  return { failures, assert };
}

// --- checks that only read the authored markup --------------------------

function detailRowsFollowTheirOwner(ctx) {
  const { failures, assert } = collector();
  ctx.rowsOf().forEach((row, i, seq) => {
    if (!row.classList.contains('detail')) { return; }
    const owner = seq[i - 1];
    assert(owner && owner.classList.contains('has-detail'),
      `detail row at position ${i} does not follow a has-detail row`);
    assert(row.cells[0].colSpan === ctx.columnCount,
      `detail row at position ${i} spans ${row.cells[0].colSpan} of ${ctx.columnCount} columns`);
  });
  ctx.items().forEach((row) => {
    if (!row.classList.contains('has-detail')) { return; }
    const next = row.nextElementSibling;
    assert(next && next.classList.contains('detail'),
      `#${row.dataset.id} is has-detail with no detail row`);
  });
  return failures;
}

// A Fix with no Goal and no Problem is instructions with nothing they are for.
// Not "all four headings": Alternatives is optional and a row may need no
// detail at all, so the pairing is the only part that is always wrong.
const DETAIL_HEADINGS = ['Goal', 'Problem', 'Fix', 'Delivered', 'Evidence', 'Alternatives'];

function headingsIn(detail) {
  return Array.from(detail.querySelectorAll('h3')).map((h) => h.textContent.trim());
}

// A review row is the one place where "what changed" and "where to check it"
// are the whole content. Without both, the reader is asked for a verdict on
// something they cannot find.
function reviewRowsCarryWhatIsReviewed(ctx) {
  const { failures, assert } = collector();
  ctx.items().filter((r) => r.dataset.action === 'review').forEach((row) => {
    const next = row.nextElementSibling;
    const detail = next && next.classList.contains('detail') ? next : null;
    assert(detail, `#${row.dataset.id} is a review with no detail - nothing says what to review`);
    const headings = detail ? headingsIn(detail) : [];
    assert(headings.includes('Delivered') && headings.includes('Evidence'),
      `#${row.dataset.id} is a review without a Delivered and an Evidence heading`);
    assert(!headings.includes('Fix'),
      `#${row.dataset.id} is a review and still has a Fix - a review asks for a verdict, not for work`);
    assert(!detail || detail.querySelector('pre, code'),
      `#${row.dataset.id} is a review that names no file, path or command to check`);
  });
  return failures;
}

// A closed row carries the order in which it closed, so trimming can keep the
// newest and drop the oldest without guessing. Duplicated indices would make
// two rows equally old and the trim arbitrary.
function closedIndexIsWellFormed(ctx) {
  const { failures, assert } = collector();
  const seen = new Map();
  ctx.items().forEach((row) => {
    const index = row.dataset.closed;
    if (row.dataset.status === 'open') {
      assert(!index, `#${row.dataset.id} is open and carries a closed index`);
      return;
    }
    assert(index, `#${row.dataset.id} is closed with no closed index`);
    if (!index) { return; }
    assert(/^\d+$/.test(index), `#${row.dataset.id} has a closed index that is not a number`);
    assert(!seen.has(index),
      `#${row.dataset.id} and #${seen.get(index)} share closed index ${index}`);
    seen.set(index, row.dataset.id);
  });
  return failures;
}

function detailFixHasAGoalOrProblem(ctx) {
  const { failures, assert } = collector();
  ctx.rowsOf().filter((r) => r.classList.contains('detail')).forEach((detail, i) => {
    const headings = headingsIn(detail);
    if (!headings.includes('Fix') && !headings.includes('Delivered')) { return; }
    assert(headings.includes('Goal') || headings.includes('Problem'),
      `the detail at position ${i} has a Fix with no Goal and no Problem`);
  });
  return failures;
}

// A misspelled heading opts a detail out of the check above without saying so.
function detailHeadingsAreKnown(ctx) {
  const { failures, assert } = collector();
  ctx.rowsOf().filter((r) => r.classList.contains('detail')).forEach((detail, i) => {
    headingsIn(detail).forEach((heading) => {
      assert(DETAIL_HEADINGS.includes(heading),
        `the detail at position ${i} has an unknown heading "${heading}"`);
    });
  });
  return failures;
}

function idsAndActionsAgree(ctx) {
  const { failures, assert } = collector();
  const seen = new Set();
  ctx.items().forEach((row) => {
    const id = row.cells[0].textContent.trim();
    assert(!seen.has(id), `duplicate ID #${id}`);
    seen.add(id);
    const classes = actionsOf(ctx).filter((a) => row.classList.contains(a));
    assert(classes.length === 1, `#${id} carries ${classes.length} action classes`);
    const cellText = (row.querySelector('td.act') || {}).firstChild;
    assert(cellText && cellText.textContent.trim() === classes[0],
      `#${id} class says ${classes[0]}, action cell says ${cellText ? cellText.textContent.trim() : 'nothing'}`);
  });
  return failures;
}

function blockersPointAtRealRows(ctx) {
  const { failures, assert } = collector();
  const ids = ctx.itemIds();
  ctx.items().forEach((row) => {
    const blocked = row.querySelector('td.act .blocked');
    if (!blocked) { return; }
    const ref = (blocked.textContent.match(/#(\d+)/) || [])[1];
    assert(ref && ids.has(ref),
      `#${row.dataset.id} is blocked by #${ref}, which is not in the register`);
  });
  return failures;
}

// An exec means "run or apply this outside the chat", so a row with nothing to
// run is mis-actioned - it reads as work and hands over none. An agent row
// closes on accepted output, which can only be judged against a specification.
// Open rows only: a closed row is the audit trail, often closed precisely
// because the mis-action was noticed.
function execAndAgentRowsCarryWhatTheyPromise(ctx) {
  const { failures, assert } = collector();
  ctx.items().filter((r) => r.dataset.status === 'open').forEach((row) => {
    const next = row.nextElementSibling;
    const detail = next && next.classList.contains('detail') ? next : null;
    if (row.dataset.action === 'exec') {
      assert(detail && detail.querySelector('pre'),
        `#${row.dataset.id} is exec with no code block in its detail`);
    }
    if (row.dataset.action === 'agent') {
      assert(detail, `#${row.dataset.id} is agent with no detail`);
    }
  });
  return failures;
}

function noAnchors(ctx) {
  const { failures, assert } = collector();
  assert(ctx.doc.querySelectorAll('a[href]').length === 0,
    '<a href> present - the host page swallows anchor clicks');
  return failures;
}

// A jump whose target is missing renders as an ordinary control that does
// nothing when pressed - invisible in the markup and on screen.
function jumpsPointAtRealTargets(ctx, inert) {
  const { failures, assert } = collector();
  const ids = ctx.itemIds();
  const epicIds = new Set(inert.epicHeaders().map((h) => h.dataset.epic).filter(Boolean));
  Array.from(ctx.doc.querySelectorAll('button.jump')).forEach((button) => {
    if (button.dataset.gotoEpic) {
      assert(epicIds.has(button.dataset.gotoEpic),
        `a jump points at epic "${button.dataset.gotoEpic}", which has no data-epic header`);
    } else {
      assert(ids.has(String(button.dataset.goto)),
        `a jump points at #${button.dataset.goto}, which is not in the register`);
    }
  });
  inert.epicHeaders().forEach((header) => {
    const blocked = header.querySelector('.blocked');
    if (!blocked) { return; }
    const name = (header.querySelector('.ename') || {}).textContent;
    assert(header.classList.contains('isblocked'),
      `epic "${name}" carries a blocker without the isblocked class`);
    assert(blocked.querySelector('button.jump[data-goto-epic]'),
      `epic "${name}" blocker is not a jump to another epic`);
  });
  return failures;
}

// The script injects the detail toggle unconditionally. An authored one has no
// handler, so two identical buttons appear and exactly one of them works.
function togglesAreGeneratedNotAuthored(ctx, inert) {
  const { failures, assert } = collector();
  inert.rowsOf().forEach((row) => {
    if (row.classList.contains('detail') || row.classList.contains('epichead')) { return; }
    const authored = row.cells[1] && row.cells[1].querySelector('.toggle, [data-det]');
    assert(!authored,
      `#${row.cells[0].textContent.trim()} has a hand-written detail toggle - the script generates it`);
  });
  ctx.rowsOf().forEach((row) => {
    if (!row.cells[1]) { return; }
    const n = row.cells[1].querySelectorAll('button.toggle').length;
    assert(n <= 1, `#${row.dataset.id} ended up with ${n} detail toggles`);
  });
  return failures;
}

// The stamp exists so a stale register fails on one comparison rather than on
// whatever feature sniff happens to have been written for it.
function templateVersionMatches(ctx) {
  const { failures, assert } = collector();
  const stamp = (ctx.doc.getElementById('grid') || {}).dataset;
  assert(stamp && stamp.tpl, 'no data-tpl on #grid - this file predates template 2.4; regenerate it');
  if (stamp && stamp.tpl) {
    assert(stamp.tpl === TPL,
      `built from template ${stamp.tpl}, verifier expects ${TPL} - regenerate it`);
  }
  return failures;
}

function codeBlocksAreWrapped(ctx) {
  const { failures, assert } = collector();
  const pres = Array.from(ctx.doc.querySelectorAll('tr.detail pre'));
  const wrapped = pres.filter((p) => p.parentNode.classList.contains('codeblock'));
  if (pres.length && !wrapped.length) {
    failures.push('no code block was given a copy button - this file predates template 2.1; regenerate it');
    return failures;
  }
  pres.forEach((pre, i) => {
    const box = pre.parentNode;
    assert(box.classList.contains('codeblock'), `code block ${i} is not wrapped`);
    const button = box.querySelector('button.copy');
    assert(button, `code block ${i} has no copy button`);
    assert(!button || button.type === 'button', `code block ${i} copy control is not type=button`);
  });
  return failures;
}

// Generated per action, so a missing set is a silent regression: the row still
// reads correctly and simply cannot be acted on.
function verdictButtonsExist(ctx) {
  const { failures, assert } = collector();
  ctx.items().forEach((row) => {
    const counts = verdictCountOf(ctx);
    const want = row.dataset.status === 'open' ? verdictCountFor(row, counts) : 0;
    const got = row.querySelectorAll('.verdict .vbtn').length;
    assert(got === want,
      `#${row.dataset.id} (${row.dataset.action}, ${row.dataset.status}) has ${got} verdict buttons, expected ${want}`);
  });
  const outbox = ctx.doc.getElementById('outbox');
  assert(outbox, 'no #outbox - this file predates template 2.9; regenerate it');
  assert(!outbox || outbox.classList.contains('empty'), 'the outbox does not start empty');
  return failures;
}

// A choice list is what the buttons are built from, so a malformed one renders
// as buttons that read wrong rather than as an error. Two choices is the
// minimum that is a choice at all.
function choiceListsAreWellFormed(ctx) {
  const { failures, assert } = collector();
  ctx.items().forEach((row) => {
    const choices = choicesOf(row);
    if (!choices) { return; }
    const id = row.dataset.id;
    assert(choices.length >= 2, `#${id} declares ${choices.length} choice(s) - a choice needs at least two`);
    assert(choices.every((choice) => choice.length > 0), `#${id} has an empty choice`);
    assert(new Set(choices).size === choices.length, `#${id} repeats a choice`);
    assert(row.dataset.status === 'open', `#${id} is closed and still declares choices`);
  });
  return failures;
}

// The recommendation column is where the answer goes. A question there asks the
// reader to supply what the row was supposed to state, and leaves every verdict
// button meaningless - agreeing to a question answers nothing.
function recommendationsAreAnswersNotQuestions(ctx) {
  const { failures, assert } = collector();
  ctx.items().forEach((row) => {
    if (row.dataset.status !== 'open') { return; }
    // The verdict buttons are injected into this cell, so read the authored
    // text only - with them included nothing ever ends with the question mark.
    const cell = row.cells[3].cloneNode(true);
    cell.querySelectorAll('.verdict').forEach((el) => el.remove());
    const text = (cell.textContent || '').trim();
    assert(!text.endsWith('?'),
      `#${row.dataset.id} recommends a question - the recommendation cell holds the answer, or the row declares data-choices`);
  });
  return failures;
}

// --- checks that press the page ----------------------------------------

// Headers are authored, so membership is position and the counts are hand
// written. Both are re-derived: a header that has drifted from its rows is the
// one epic failure that looks entirely correct on screen.
function epicsHoldTheirRows(ctx, inert) {
  const { failures, assert } = collector();
  if (!ctx.epicHeaders().length) { return failures; }

  const authored = inert.rowsOf();
  const liveById = new Map(ctx.rowsOf().filter((r) => r.dataset.id).map((r) => [r.dataset.id, r]));
  const expected = new Set();

  inert.epicHeaders().forEach((header) => {
    assert(header.cells[0].colSpan === ctx.columnCount,
      `epic header spans ${header.cells[0].colSpan} of ${ctx.columnCount} columns`);
    const nameEl = header.querySelector('.ename');
    assert(nameEl && nameEl.textContent.trim(), 'epic header has no .ename');
    const name = nameEl ? nameEl.textContent.trim() : '(unnamed)';
    assert(header.querySelector('button.gtoggle'), `epic header "${name}" has no collapse button`);

    const members = [];
    let i = authored.indexOf(header) + 1;
    while (i < authored.length && !authored[i].classList.contains('epichead')
           && !authored[i].classList.contains('blockend')) {
      if (!authored[i].classList.contains('detail')) { members.push(authored[i]); }
      i++;
    }
    assert(members.length > 0, `epic header "${name}" has no rows under it`);
    members.forEach((row) => {
      const id = row.cells[0].textContent.trim();
      expected.add(id);
      const live = liveById.get(id);
      assert(live && live.classList.contains('inepic'),
        `#${id} under "${name}" is not marked as a member`);
    });

    const count = header.querySelector('.gcount');
    assert(!count || !count.textContent.trim(),
      `epic header "${name}" has a hand-written count - the script generates it`);
  });

  ctx.items().filter((r) => r.classList.contains('inepic')).forEach((row) => {
    assert(expected.has(row.dataset.id),
      `#${row.dataset.id} carries the epic marker without sitting under an epic header`);
  });
  return failures;
}

// Demotion is the one thing that moves a block, so it gets asserted rather
// than assumed: a block with nothing open must not sit above a live one.
function finishedEpicsSinkBelowLiveOnes(ctx) {
  const { failures, assert } = collector();
  if (!ctx.epicHeaders().length) { return failures; }
  const hasOpen = [];
  ctx.rowsOf().forEach((row) => {
    if (row.classList.contains('epichead')) { hasOpen.push(false); return; }
    if (row.classList.contains('detail') || row.classList.contains('blockend')) { return; }
    if (!hasOpen.length) { hasOpen.push(false); }
    if (row.dataset.status === 'open') { hasOpen[hasOpen.length - 1] = true; }
  });
  const lastLive = hasOpen.lastIndexOf(true);
  hasOpen.slice(0, lastLive).forEach((live, i) => {
    assert(live, `a block with nothing open sits at position ${i}, above a block that has open rows`);
  });
  return failures;
}

// Closed rows are hidden by default, so a block that is entirely finished has a
// hidden header and nothing to collapse. Reveal everything first, or this
// reports the default as a collapse bug.
function collapsingAnEpicIsReversible(ctx) {
  const { failures, assert } = collector();
  if (!ctx.epicHeaders().length) { return failures; }
  statusesOf(ctx).forEach((k) => { const c = ctx.chip(k); if (c) { ctx.click(c); } });
  const header = ctx.epicHeaders()[0];
  const before = ctx.visibleRows().length;
  const toggle = header.querySelector('button.gtoggle');
  ctx.click(toggle);
  assert(!header.hidden, 'collapsing an epic hid its own header');
  assert(toggle.textContent.trim() === 'show', 'collapse did not flip the button label');
  ctx.click(toggle);
  assert(ctx.visibleRows().length === before,
    `expand did not restore the block (${ctx.visibleRows().length} of ${before})`);
  return failures;
}

function sortingOverEpicsSaysSo(ctx) {
  const { failures, assert } = collector();
  if (!ctx.epicHeaders().length) { return failures; }
  const hint = ctx.doc.getElementById('hint');
  if (!hint) {
    failures.push('no sort hint element - this file predates template 2.2; regenerate it');
    return failures;
  }
  ctx.click(ctx.doc.querySelector('th[data-sort="id"]'));
  // With nothing visible the hint is the empty-state message instead, and that
  // is correct - the sort note would be advice about an empty table.
  const anyOpen = ctx.items().some((r) => r.dataset.status === 'open');
  assert(!anyOpen || hint.textContent.trim() === 'sorted within each block',
    'a sort over authored headers does not say it only reordered within blocks');
  assert(anyOpen || /show resolved/.test(hint.textContent),
    'an all-closed register renders empty without saying why');
  return failures;
}

function filteringHidesAndRestores(ctx) {
  const { failures, assert } = collector();
  const box = ctx.doc.getElementById('q');
  const type = (value) => {
    box.value = value;
    box.dispatchEvent(new ctx.win.Event('input'));
  };
  type('zzzz-no-such-text');
  assert(ctx.visibleRows().length === 0, 'a filter matching nothing still shows rows');
  type('');
  // Closed rows are out by default, so clearing the box restores the open ones
  // only. Asserting "every row" here would make the default a failure.
  assert(ctx.items().filter((r) => r.dataset.status === 'open').every((r) => !r.hidden),
    'clearing the filter did not restore the open rows');
  assert(ctx.items().filter((r) => r.dataset.status !== 'open').every((r) => r.hidden),
    'a closed row is visible with no status chip pressed');
  return failures;
}

function statusChipsWiden(ctx) {
  const { failures, assert } = collector();
  statusesOf(ctx).forEach((status) => {
    const chip = ctx.chip(status);
    if (!chip) { return; }
    assert(/^show /.test(chip.textContent), `the ${status} chip is not labelled with its effect`);
    ctx.click(chip);
    assert(ctx.items().filter((r) => r.dataset.status === status).every((r) => !r.hidden),
      `pressing "show ${status}" did not reveal the ${status} rows`);
    assert(ctx.items().filter((r) => r.dataset.status === 'open').every((r) => !r.hidden),
      `pressing "show ${status}" hid the open rows - a status chip widens, it does not narrow`);
    ctx.click(chip);
  });
  return failures;
}

// A superseded row points somewhere. Without the pointer the reader has a row
// that says "not this one" and no way to find the live version.
function supersededRowsNameTheirSuccessor(ctx) {
  const { failures, assert } = collector();
  const ids = ctx.itemIds();
  ctx.items().filter((r) => r.dataset.status === 'superseded').forEach((row) => {
    const refs = (row.textContent.match(/#(\d+)/g) || [])
      .map((m) => m.slice(1))
      .filter((id) => id !== row.dataset.id && ids.has(id));
    assert(refs.length > 0,
      `#${row.dataset.id} is superseded and names no row that supersedes it`);
  });
  return failures;
}

// A blocker whose target has closed is satisfied, and leaving it on the row
// keeps work parked that nothing is holding. It reads as current because a
// blocker is written to be read first, and with closed rows hidden by default
// the target looks absent rather than done.
function openRowsAreNotBlockedByClosedRows(ctx) {
  const { failures, assert } = collector();
  const byId = new Map(ctx.items().map((r) => [r.dataset.id, r]));
  ctx.items().filter((r) => r.dataset.status === 'open').forEach((row) => {
    const blocked = row.querySelector('td.act .blocked');
    if (!blocked) { return; }
    (blocked.textContent.match(/#(\d+)/g) || []).map((m) => m.slice(1)).forEach((ref) => {
      const target = byId.get(ref);
      assert(!target || target.dataset.status === 'open',
        `#${row.dataset.id} is blocked by #${ref}, which is closed - the blocker is satisfied`);
    });
  });
  return failures;
}

// A blocker on a closed row is stale by definition: the work behind it either
// happened or was abandoned, and either way the block is not what is true now.
function closedRowsCarryNoBlocker(ctx) {
  const { failures, assert } = collector();
  const byId = new Map(ctx.items().map((r) => [r.dataset.id, r]));
  ctx.items().filter((r) => r.dataset.status !== 'open').forEach((row) => {
    const blocked = row.querySelector('td.act .blocked');
    if (!blocked) { return; }
    const ref = (blocked.textContent.match(/#(\d+)/) || [])[1];
    const target = ref && byId.get(ref);
    assert(!target || target.dataset.status !== 'open',
      `#${row.dataset.id} is closed but still blocked by #${ref}, which is open`);
  });
  return failures;
}

// --- differential, against the previous register ------------------------
// The register is rewritten in place every turn, so every row is re-authored
// from whatever the author has in front of them - and a collapsed detail under
// a closed row is precisely what they do not. That loss is invisible in the
// file being checked, which is why checking it needs the old one.
function detailsSurvived(inert, previous, previousName) {
  const { failures, assert } = collector();
  const ownersWithDetail = (context) => {
    const out = new Set();
    context.rowsOf().forEach((row, i, seq) => {
      if (!row.classList.contains('detail')) { return; }
      const owner = seq[i - 1];
      if (owner && owner.cells[0]) { out.add(owner.cells[0].textContent.trim()); }
    });
    return out;
  };
  const had = ownersWithDetail(previous);
  const has = ownersWithDetail(inert);
  const present = inert.itemIds();
  had.forEach((id) => {
    // A pruned row takes its detail with it; only a surviving row can lose one.
    if (!present.has(id)) { return; }
    assert(has.has(id), `#${id} had a detail in ${previousName} and has none now`);
  });
  return failures;
}

// Closed rows are trimmed to the newest CLOSED_KEPT, except that a row closed in
// this same write is never trimmed - a batch of twenty closures is all readable
// once, and the next write brings the count back down.
function closedRowsAreTrimmed(inert, previous) {
  const { failures, assert } = collector();
  // An inert parse has no dataset - the page script sets it - so identity and
  // action come from the markup here, not from the properties.
  const idOf = (row) => row.cells[0].textContent.trim();
  const actionOf = (row) => actionsOf(inert).find((a) => row.classList.contains(a));
  const indexOf = (row) => Number(row.dataset.closed || 0);
  const closed = inert.items().filter((r) => /resolved|superseded/.test(r.className));
  const wasOpen = new Set(previous.items()
    .filter((r) => !/resolved|superseded/.test(r.className)).map(idOf));
  const newlyClosed = closed.filter((r) => wasOpen.has(idOf(r)));
  const keep = new Set(newlyClosed.map(idOf));
  closed.slice().sort((a, b) => indexOf(b) - indexOf(a)).slice(0, CLOSED_KEPT).forEach((r) => keep.add(idOf(r)));
  closed.forEach((row) => {
    assert(keep.has(idOf(row)),
      `#${idOf(row)} is closed, not closed in this write, and not among the newest ${CLOSED_KEPT} - archive it`);
  });
  // No ordering assertion here. Several close commands can run between two
  // saved registers, and the file cannot tell one batch from three - the
  // indices are contiguous either way. register.js sorts a batch by action rank
  // then ID as it writes, which is the only place the batch is still visible.
  return failures;
}

// Every row that was open must still be here. A drop is explicit and usually
// follows a close, so a missing open row is a loss until you say otherwise.
function openRowsSurvived(inert, previous, previousName) {
  const { failures, assert } = collector();
  const present = inert.itemIds();
  previous.items().filter((r) => r.dataset.status === 'open'
    || !r.className.match(/resolved|superseded/)).forEach((row) => {
    const id = row.cells[0].textContent.trim();
    assert(present.has(id), `#${id} was open in ${previousName} and is not in this register`);
  });
  return failures;
}

// Closing is one-way. A row that reopens does so under a new ID, which is what
// keeps an answered question from turning back into an open one in silence.
function closedRowsStayClosed(inert, previous, previousName) {
  const { failures, assert } = collector();
  const now = new Map(inert.items().map((r) => [r.cells[0].textContent.trim(), r]));
  previous.items().forEach((row) => {
    if (!/resolved|superseded/.test(row.className)) { return; }
    const id = row.cells[0].textContent.trim();
    const current = now.get(id);
    if (!current) { return; }
    assert(/resolved|superseded/.test(current.className),
      `#${id} was closed in ${previousName} and is open again - reopen under a new ID`);
  });
  return failures;
}

// IDs are monotonic, so any number at or below the previous high-water mark was
// already handed out. A new row wearing an old number is a reused ID.
function idsOnlyGrow(inert, previous, previousName) {
  const { failures, assert } = collector();
  const before = new Set(previous.items().map((r) => r.cells[0].textContent.trim()));
  const highWater = Math.max(0, ...Array.from(before, Number).filter(Number.isFinite));
  inert.items().forEach((row) => {
    const id = row.cells[0].textContent.trim();
    if (Number(id) > highWater) { return; }
    assert(before.has(id),
      `#${id} is new but sits below the highest ID in ${previousName} (#${highWater}) - IDs are never reused`);
  });
  return failures;
}

// The action records who the row is waiting on. It may change only when the
// actor changes and the item does not: delivered agent work becomes a review
// for the reader. Any other change rewrites what the row had asked for.
const ALLOWED_ACTION_MOVES = { agent: ['review'] };

function actionOnlyMovesToItsReviewer(inert, previous, previousName) {
  const { failures, assert } = collector();
  const actionOf = (row) => actionsOf(inert).find((a) => row.classList.contains(a));
  const was = new Map(previous.items().map((r) => [r.cells[0].textContent.trim(), actionOf(r)]));
  inert.items().forEach((row) => {
    const id = row.cells[0].textContent.trim();
    if (!was.has(id) || !was.get(id)) { return; }
    const before = was.get(id), now = actionOf(row);
    const allowed = (ALLOWED_ACTION_MOVES[before] || []).includes(now);
    assert(now === before || allowed,
      `#${id} was ${before} in ${previousName} and is ${now} now - only agent may become review`);
  });
  return failures;
}

const readOnlyChecks = {
  detailRowsFollowTheirOwner,
  idsAndActionsAgree,
  blockersPointAtRealRows,
  execAndAgentRowsCarryWhatTheyPromise,
  noAnchors,
  templateVersionMatches,
  codeBlocksAreWrapped,
  verdictButtonsExist,
  choiceListsAreWellFormed,
  recommendationsAreAnswersNotQuestions,
  finishedEpicsSinkBelowLiveOnes,
  supersededRowsNameTheirSuccessor,
  closedRowsCarryNoBlocker,
  openRowsAreNotBlockedByClosedRows,
  detailFixHasAGoalOrProblem,
  detailHeadingsAreKnown,
  reviewRowsCarryWhatIsReviewed,
  closedIndexIsWellFormed
};

const readOnlyChecksNeedingInert = {
  jumpsPointAtRealTargets,
  togglesAreGeneratedNotAuthored,
  epicsHoldTheirRows
};

// Against the previous register. Each takes the inert parse of both files.
const differentialChecks = {
  detailsSurvived,
  openRowsSurvived,
  closedRowsStayClosed,
  idsOnlyGrow,
  actionOnlyMovesToItsReviewer,
  closedRowsAreTrimmed
};

const interactiveChecks = {
  collapsingAnEpicIsReversible,
  sortingOverEpicsSaysSo,
  filteringHidesAndRestores,
  statusChipsWiden
};

// One pass over everything, for the CLI. Read-only checks share a context;
// each interactive check gets its own, so none of them can see what another
// one pressed.
function runAll(src, previousSrc, previousName) {
  const live = liveContext(src);
  const inert = inertContext(src);
  inert.contract = live.contract;
  const failures = [];
  Object.values(readOnlyChecks).forEach((check) => failures.push(...check(live)));
  Object.values(readOnlyChecksNeedingInert).forEach((check) => failures.push(...check(live, inert)));
  Object.values(interactiveChecks).forEach((check) => {
    failures.push(...check(freshContext(src), inert));
  });
  if (previousSrc) {
    const previous = inertContext(previousSrc);
    Object.values(differentialChecks).forEach((check) => {
      failures.push(...check(inert, previous, previousName));
    });
  }
  return {
    failures,
    itemCount: live.items().length,
    epicCount: live.epicHeaders().length,
    codeBlockCount: live.doc.querySelectorAll('tr.detail pre').length
  };
}

module.exports = {
  TPL,
  CLOSED_KEPT,
  DETAIL_HEADINGS,
  FALLBACK_CONTRACT,
  verdictCountOf,
  choicesOf,
  inertContext,
  liveContext,
  freshContext,
  readOnlyChecks,
  readOnlyChecksNeedingInert,
  interactiveChecks,
  differentialChecks,
  runAll
};
