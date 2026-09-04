// One mutation per check: a small edit to a register that the named check must
// reject. A check that cannot be made to fail is not evidence of anything, and
// the failure mode is silent - a broken selector returns no failures, which
// reads exactly like success.
//
// Each entry returns the mutated source, or null when this register cannot
// carry that mutation (no epics, no exec rows). The suite reports those as
// skipped with the reason rather than passing them.

const first = (src, needle, replacement) =>
  (src.includes(needle) ? src.replace(needle, replacement) : null);

// Drops a whole row and its detail, by ID.
function removeRow(src, id) {
  const pattern = new RegExp(
    `<tr class="[^"]*"><td class="id">${id}</td>[\\s\\S]*?</tr>\\n(<tr class="detail" hidden>[\\s\\S]*?</tr>\\n)?`);
  return pattern.test(src) ? src.replace(pattern, '') : null;
}

function firstOpenId(src) {
  const m = src.match(/<tr class="(?![^"]*(?:resolved|superseded))[^"]*"><td class="id">(\d+)<\/td>/);
  return m ? m[1] : null;
}

function firstClosedId(src) {
  const m = src.match(/<tr class="[^"]*resolved[^"]*"><td class="id">(\d+)<\/td>/);
  return m ? m[1] : null;
}

const mutations = {
  detailRowsFollowTheirOwner: (src) =>
    first(src, '<tr class="detail" hidden>', '<tr class="detail" hidden data-orphan="1">')
      && src.replace(/(<tr class="[^"]*has-detail"[\s\S]*?<\/tr>\n)(<tr class="detail" hidden>)/,
        '$1<tr class="ack"><td class="id">9001</td><td>wedge</td><td class="act">ack</td><td>-</td><td>-</td></tr>\n$2'),

  idsAndActionsAgree: (src) =>
    src.replace(/(<tr class="[^"]*\b(decide|exec|agent|ack|paste)\b[^"]*"[\s\S]{0,400}?<td class="act">)[a-z]+/,
      '$1nonsense'),

  blockersPointAtRealRows: (src) => {
    const open = firstOpenId(src);
    if (!open) { return null; }
    return src.replace(
      new RegExp(`(<tr class="(?![^"]*(?:resolved|superseded))[^"]*"><td class="id">${open}</td>[\\s\\S]*?<td class="act">[a-z]+)`),
      '$1<span class="blocked">blocked by <button type="button" class="jump" data-goto="9001">#9001</button></span>');
  },

  // Attributes may sit between the class and the first cell on a closed row, and
  // the open exec row this needs may be anywhere in the file.
  execAndAgentRowsCarryWhatTheyPromise: (src) => {
    const m = src.match(/<tr class="(?![^"]*(?:resolved|superseded))[^"]*\bexec\b[^"]*"[^>]*>[\s\S]*?<\/tr>\n<tr class="detail" hidden>[\s\S]*?<\/tr>\n/);
    if (!m) { return null; }
    return src.replace(m[0], m[0].replace(/<pre>/g, '<p class="was-pre">').replace(/<\/pre>/g, '</p>'));
  },

  noAnchors: (src) => first(src, '<tbody>', '<tbody><tr><td><a href="#x">x</a></td></tr>'),

  templateVersionMatches: (src) => src.replace(/data-tpl="\d+"/, 'data-tpl="0"'),

  // The class drives both the expectation and the generation, so relabelling
  // cannot desync them. An authored button on a closed row can.
  verdictButtonsExist: (src) => {
    const closed = firstClosedId(src);
    if (!closed) { return null; }
    return src.replace(
      new RegExp(`(<tr class="[^"]*resolved[^"]*"><td class="id">${closed}</td><td>[\\s\\S]*?</td><td class="act">[\\s\\S]*?</td><td>)`),
      '$1<div class="verdict"><button type="button" class="vbtn yes">x</button></div>');
  },

  choiceListsAreWellFormed: (src) => {
    const open = firstOpenId(src);
    if (!open) { return null; }
    return src.replace(
      new RegExp(`(<tr class="(?![^"]*(?:resolved|superseded))[^"]*)("><td class="id">${open}</td>)`),
      '$1" data-choices="A|A$2');
  },

  recommendationsAreAnswersNotQuestions: (src) => {
    const open = firstOpenId(src);
    if (!open) { return null; }
    return src.replace(
      new RegExp(`(<tr class="(?![^"]*(?:resolved|superseded))[^"]*"><td class="id">${open}</td><td>[\\s\\S]*?</td><td class="act">[\\s\\S]*?</td><td>)([\\s\\S]*?)(</td>)`),
      '$1Which one do you want?$3');
  },

  supersededRowsNameTheirSuccessor: (src) => {
    const m = src.match(/<tr class="[^"]*superseded[^"]*"><td class="id">(\d+)<\/td>[\s\S]*?<\/tr>/);
    if (!m) { return null; }
    return src.replace(m[0], m[0].replace(/#\d+/g, 'a later row'));
  },

  closedRowsCarryNoBlocker: (src) => {
    const open = firstOpenId(src), closed = firstClosedId(src);
    if (!open || !closed) { return null; }
    return src.replace(
      new RegExp(`(<tr class="[^"]*resolved[^"]*"><td class="id">${closed}</td>[\\s\\S]*?<td class="act">[a-z]+)`),
      `$1<span class="blocked">blocked by <button type="button" class="jump" data-goto="${open}">#${open}</button></span>`);
  },

  openRowsAreNotBlockedByClosedRows: (src) => {
    const open = firstOpenId(src), closed = firstClosedId(src);
    if (!open || !closed) { return null; }
    return src.replace(
      new RegExp(`(<tr class="(?![^"]*(?:resolved|superseded))[^"]*"><td class="id">${open}</td>[\\s\\S]*?<td class="act">[a-z]+)`),
      `$1<span class="blocked">blocked by <button type="button" class="jump" data-goto="${closed}">#${closed}</button></span>`);
  },

  // The page script only builds a jump for an ID it knows, so a bare "#9001"
  // in prose stays plain text. The dangling button has to be authored.
  jumpsPointAtRealTargets: (src) =>
    first(src, '</tbody>',
      '<tr class="ack"><td class="id">9002</td><td>x <button type="button" class="jump" data-goto="9001">#9001</button></td>'
      + '<td class="act">ack</td><td>-</td><td>-</td></tr>\n</tbody>'),

  togglesAreGeneratedNotAuthored: (src) =>
    src.replace(/(<tr class="[^"]*has-detail"><td class="id">\d+<\/td><td>)/,
      '$1<button type="button" class="toggle">details</button>'),

  // Both openers have to go: a detail with Goal and Problem still passes when
  // only one of them is renamed.
  detailFixHasAGoalOrProblem: (src) => {
    const m = src.match(/<tr class="detail" hidden><td colspan="\d+">[\s\S]*?<h3>Fix<\/h3>/);
    if (!m) { return null; }
    return src.replace(m[0], m[0].replace(/<h3>Goal<\/h3>/g, '<h3>Alternatives</h3>')
      .replace(/<h3>Problem<\/h3>/g, '<h3>Alternatives</h3>'));
  },

  closedIndexIsWellFormed: (src) =>
    src.replace(/ data-closed="\d+"/, ''),

  // The mutation runs against itself as the previous register, so every closed
  // row counts as already closed and none is exempt. An extra one past the keep
  // limit is what has to fail.
  // One extra closed row proves nothing: the check only bites past CLOSED_KEPT,
  // so the mutation has to fill the window and push whatever was already closed
  // out of it. Those rows were closed in the previous register too, so they are
  // not exempt as newly closed and must be reported as needing the archive.
  closedRowsAreTrimmed: (src) => {
    if (!/(resolved|superseded)/.test(src)) { return null; }
    const highest = Math.max(0, ...Array.from(src.matchAll(/data-closed="(\d+)"/g), (m) => Number(m[1])));
    const filler = Array.from({ length: 15 }, (unused, i) =>
      `<tr class="ack resolved" data-closed="${highest + 1 + i}"><td class="id">${9001 + i}</td>`
      + '<td>a newer closed row</td><td class="act">ack<span class="mark">\u2705</span></td>'
      + '<td>-</td><td>-</td></tr>').join('\n');
    return src.replace('<tbody>\n', `<tbody>\n${filler}\n`);
  },

  detailHeadingsAreKnown: (src) => first(src, '<h3>Fix</h3>', '<h3>Solution</h3>'),

  reviewRowsCarryWhatIsReviewed: (src) =>
    (src.includes('<tr class="review has-detail">')
      ? src.replace(/(<tr class="review has-detail">[\s\S]*?<tr class="detail" hidden>[\s\S]*?)<h3>Evidence<\/h3>/,
          '$1<h3>Alternatives</h3>')
      : null),

  // Differential. These mutate the file being checked; the unmutated source is
  // passed as the previous register.
  detailsSurvived: (src) => src.replace(/<tr class="detail" hidden>[\s\S]*?<\/tr>\n/, ''),
  openRowsSurvived: (src) => removeRow(src, firstOpenId(src)),
  closedRowsStayClosed: (src) => {
    const closed = firstClosedId(src);
    if (!closed) { return null; }
    return src.replace(new RegExp(`(<tr class="[^"]*)resolved([^"]*"><td class="id">${closed}</td>)`), '$1$2');
  },
  // A number below the high-water mark that was never handed out. Reusing an ID
  // that did exist is invisible by design - the check is about renumbering.
  idsOnlyGrow: (src) => {
    const ids = new Set(Array.from(src.matchAll(/<td class="id">(\d+)<\/td>/g), (m) => Number(m[1])));
    const highWater = Math.max(...ids);
    let gap = null;
    for (let i = 1; i < highWater; i++) { if (!ids.has(i)) { gap = i; break; } }
    if (gap === null) { return null; }
    return src.replace('<tbody>\n',
      `<tbody>\n<tr class="ack"><td class="id">${gap}</td><td>a number never handed out</td><td class="act">ack</td><td>-</td><td>-</td></tr>\n`);
  },
  actionOnlyMovesToItsReviewer: (src) => {
    const closed = firstClosedId(src);
    if (!closed) { return null; }
    return src.replace(
      new RegExp(`(<tr class="[^"]*)(decide|exec|agent|paste|review)([^"]*resolved[^"]*"><td class="id">${closed}</td>)`),
      '$1ack$3');
  }
};

// Checks with no mutation, and why. The suite asserts this list plus the
// mutation list covers every check, so a new check cannot be added without
// either proving it fails or saying out loud that it is unproven.
const unmutated = {
  codeBlocksAreWrapped: 'the wrapping is done by the page script - breaking it means breaking the script, not the register',
  finishedEpicsSinkBelowLiveOnes: 'the ordering is done by the page script',
  epicsHoldTheirRows: 'membership is derived by the page script from authored position',
  collapsingAnEpicIsReversible: 'asserts page behaviour, not register content',
  sortingOverEpicsSaysSo: 'asserts page behaviour, not register content',
  filteringHidesAndRestores: 'asserts page behaviour, not register content',
  statusChipsWiden: 'asserts page behaviour, not register content'
};

module.exports = { mutations, unmutated };
