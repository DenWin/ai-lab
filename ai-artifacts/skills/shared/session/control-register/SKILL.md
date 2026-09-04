---
name: control-register
description: Render the decision-points control register as a self-contained HTML page with filter chips, sortable columns, expand-in-place detail rows, numbered code blocks, per-row verdict buttons feeding a single copyable outbox, jump buttons on every cross-reference, and collapsible epic header rows that can carry a model assignment and a blocker on the whole epic. Use when creating, writing, updating, revising, or rewriting `control-register.html`, whenever the protocol calls for emitting or refreshing the control register, and whenever rows are to be grouped into an epic or assigned to a particular model.
metadata:
  version: 2.33.0
---

# Control Register

Rendering only. The protocol - when a register is emitted, what an action means,
how rows close - lives in the user's instructions, not here.

## Quick start

Copy `assets/template.html` and replace the rows between `<tbody>` and
`</tbody>`. Nothing else in the file changes between turns; the CSS and script
are fixed. The protocol names the container to write it to and the lifecycle
that governs it.

`assets/template.html` typically sits on a read-only mount. A plain `cp`
carries the source's mode bits over, so the copy is read-only too and the
first edit fails; `chmod` the copy before writing to it.

A row, and an optional detail row immediately after it:

```html
<tr class="exec has-detail"><td class="id">13</td><td>Deploy the file</td><td class="act">exec<span class="blocked">blocked by <button type="button" class="jump" data-goto="35">#35</button></span></td><td>Run the script in the detail</td><td>Unblocked once #35 lands</td></tr>
<tr class="detail" hidden><td colspan="5">
<h3>Fix</h3>
<pre><code>Copy-Item ./build/out.html $target</code></pre>
</td></tr>
```

```html
<tr class="ack has-detail"><td class="id">14</td><td>Library choice</td><td class="act">ack</td><td>Picked X over Y</td><td>Open the detail for the tradeoff</td></tr>
<tr class="detail" hidden><td colspan="5">
<h3>Alternatives</h3>
<p>Y was rejected because ...</p>
</td></tr>
```

A row for work an agent will build - specified here, produced elsewhere:

```html
<tr class="agent has-detail"><td class="id">17</td><td>Build the import parser</td><td class="act">agent</td><td>Scope, inputs and acceptance in the detail</td><td>Closes when the output lands and is accepted</td></tr>
<tr class="detail" hidden><td colspan="5">
<h3>Goal</h3>
<p>Imports land parsed, with bad rows named rather than dropped.</p>
<h3>Fix</h3>
<p>Inputs, scope and what counts as accepted.</p>
</td></tr>
```

An epic: a header row, then the rows that belong to it. Membership is
position - everything up to the next header, or the end of the table.

```html
<tr class="epichead" data-epic="validator"><td colspan="5"><span class="ename">Phase 1 - Validator</span><span class="model">Sonnet</span><span class="gcount">1 decide · 2 exec</span><button type="button" class="toggle gtoggle">hide</button></td></tr>
<tr class="decide"><td class="id">15</td><td>Validator as keeper or throwaway</td><td class="act">decide</td><td>Keeper</td><td>The hook re-runs it</td></tr>
<tr class="exec"><td class="id">16</td><td>Build kk-validate</td><td class="act">exec</td><td>What to build</td><td>Why it comes first</td></tr>
```

A whole block blocked by an earlier one:

```html
<tr class="epichead isblocked" data-epic="rollout"><td colspan="5"><span class="ename">Phase 2 - Rollout</span><span class="gcount">1 exec</span><button type="button" class="toggle gtoggle">hide</button><span class="blocked">blocked by <button type="button" class="jump" data-goto-epic="validator">Phase 1 - Validator</button></span></td></tr>
```

## Workflows

### Emitting or refreshing the block

- [ ] Start from `assets/template.html`; do not hand-write the CSS or script.
- [ ] Read the existing register first, and carry every detail row forward
      verbatim unless its row is being pruned. Rewriting in place means every
      row is re-authored from what is currently in front of you, and a
      collapsed detail under a closed row is exactly what is not: one line of
      hidden markup that nothing on screen reminds you of. Dropping it is
      silent, the page still verifies clean, and it destroys what the closed
      row was kept for - a decision recorded without its reasoning.
- [ ] One `<tr>` per row. `class` carries the action - `decide`, `paste`, `exec`,
      `review`, `agent`, `ack` - plus, once closed, a status class `resolved` or
      `superseded`. The script reads both, so they must match the visible text.
- [ ] A closed row keeps its action and gains a mark in the action cell:
      `<span class="mark">✅</span>` resolved, `↩️` superseded.
- [ ] Mark a row that has a detail with `has-detail`, and place the
      `<tr class="detail" hidden>` immediately after it. The script pairs them
      by position; a detail row that is not preceded by its own row attaches to
      the wrong item silently.
- [ ] A row that asks which of several named options wins carries
      `data-choices="A|B"` and states nothing in the recommendation cell that
      ends in a question mark. Both are checked: a question in that cell is the
      row failing to answer what it was written to answer.
- [ ] A blocker goes inside the action cell as
      `<span class="blocked">blocked by #N</span>`, never in the rationale.
- [ ] An epic is a `tr.epichead` you write, followed by its rows. The header
      cell spans every column and holds, in order: `.ename`, an optional
      `.model`, and the `button.gtoggle` that collapses the block. The count
      between them is generated - authoring one is the same mistake as
      authoring the toggle. Give it a `data-epic` so it can be referenced.
      Never use `epic` as an action.
- [ ] Order the blocks yourself, most urgent first, and put each block's rows
      in reading order. A header holds its place, so a sort only reorders rows
      inside one. The single exception: a block in which every row is closed
      drops below every block that still has something open. That is
      open-before-closed applied one level up, and it is why a finished phase
      does not have to be hand-moved to the bottom to stay out of the way.
- [ ] A block runs to the next header or to the end of the table. To put rows
      back outside a block - so an urgent block can sit at the top and loose
      rows still follow it - close it with
      `<tr class="blockend" hidden><td colspan="5"></td></tr>`. Omit it when
      every block is at the bottom; it renders nothing either way.
- [ ] Within a block, and among rows with no header above them, emit in any
      order - the script sorts each partition. Carry forward any `<colgroup>`
      widths the user has changed.
- [ ] An open `exec` row needs a detail containing a `<pre>`, and an open
      `agent` row needs a detail at all. Both actions promise something the row
      has to carry: an exec hands over something to run, and an agent row is
      judged on output against a specification. A row that promises either and
      contains neither reads as ordinary work and hands over nothing, so
      `scripts/verify.js` fails on it. If there is genuinely nothing to run,
      the row is not an exec. Closed rows are exempt - they are the audit
      trail, carried forward verbatim, and a mis-action noticed at closing time
      is recorded rather than edited away.
- [ ] Put anything meant to be run inside `<pre><code>` in a detail row; line
      numbers and the copy button are generated for every one of them. A
      command left in the recommendation cell as inline `<code>` gets neither.
- [ ] **Never author a control the script generates.** The detail toggle and
      the verdict buttons are injected. A hand-written toggle carries no
      handler, so two identical buttons appear and exactly one works. The
      script strips a stale one and `scripts/verify.js` fails on it, but the
      markup still should not contain it.
- [ ] Write a cross-reference as plain `#n`. Every `#n` in prose that matches a
      row becomes a jump button on load - authoring that button is the same
      mistake as authoring the toggle. Inside `<code>` or `<pre>` it is left
      alone, which is how a literal `#12` in a snippet stays text. The one
      place the button is written by hand is a blocker, because it has to sit
      inside `span.blocked`.
- [ ] A blocker on a whole block goes in the header, not on each member:
      `class="epichead isblocked"` plus `<span class="blocked">blocked by
      <button type="button" class="jump" data-goto-epic="ID">Name</button></span>`,
      where `ID` is the target header's `data-epic`. Row-level `blocked by #N`
      stays for dependencies inside a block; the two filters are separate
      because hiding blocked rows leaves the members of a blocked block on
      screen, individually unblocked and collectively not actionable.
- [ ] Verify before delivering. Where `node` is available this is a command
      rather than a reading exercise - it catches pairing, action/class
      mismatches, dangling blockers, dead jumps, authored toggles, exec rows
      with nothing to run, agent rows with nothing specified, missing verdict
      buttons and stale templates:

```bash
npm install jsdom && node scripts/verify.js control-register.html
```

`require('jsdom')` resolves from `scripts/verify.js`'s own directory, not from
your shell's cwd. If that directory is on a read-only mount, an `npm install`
run elsewhere is invisible to it - point Node at it explicitly:

```bash
npm install --prefix /tmp/cb-deps jsdom
NODE_PATH=/tmp/cb-deps/node_modules node scripts/verify.js control-register.html
```

Pass the previous register as a second argument where you still have it -
`node scripts/verify.js new.html old.html` - and it also fails on any detail
that existed then and does not now. That is the one loss the file itself cannot
show you.

Otherwise check by eye. Membership is position, so the checks are positional
too: every `has-detail` has a following detail row, every detail row follows a
`has-detail`, every `tr.epichead` has at least one row beneath it, no epic
header carries a hand-written count, every `data-goto` and `data-goto-epic`
names something that exists, every open `exec` row has a `<pre>` in its detail
and every open `agent` row has a detail, no item cell contains an authored
toggle, and no `<a href>` appears anywhere in the file.

### Changing the rendering itself

- [ ] Edit `assets/template.html`, not the generated file - a generated file is
      overwritten next turn.
- [ ] Re-read [REFERENCE.md](REFERENCE.md) first; several of the constraints
      there are non-obvious and were expensive to find.
- [ ] Run `scripts/verify.js` against the template and against a register with
      epics, closed rows and code blocks. Every failure it checks for renders
      as a plausible-looking page, so eyeballing does not find them.
- [ ] Check both widths. The desktop layout hides mobile breakage completely.
- [ ] Adding a new action value is five edits, not three - `RANK`, a colour
      rule, a chip border colour, the `ACTIONS` constant in
      `scripts/verify.js`, and a `VERDICTS` entry (or a deliberate omission,
      as `paste` has). The verifier constant is the one that gets missed, and
      it does not break rendering; it makes the verifier blame the register for
      a stale constant in itself.
- [ ] Bump `metadata.version` here for any change to this skill, documentation
      included. It tracks the skill, nothing else.
- [ ] Bump `data-tpl` on `<table id="grid">` in the template and the `TPL`
      constant in `scripts/verify.js` together, and only when the markup, CSS
      or script changes. That pair is a compatibility contract - it is what
      makes a stale register fail on one comparison rather than on whichever
      missing feature someone thought to sniff for - so a documentation change
      must leave it alone. Example rows inside `<tbody>` are placeholder
      content that an author replaces wholesale, so changing them is not a
      markup change either. A stricter check in `scripts/checks.js` over
      unchanged markup is likewise not a bump: the stamp answers "is this
      file's markup too old for the verifier", and a new finding in an old
      register is a finding, not an incompatibility. The value is an opaque
      counter, `1`, `2`, `3`:
      ordered, so a mismatch says which of the two is behind, and deliberately
      unlike `metadata.version`, so the two can never be read as one number.

## Notes

- Self-contained: inline `<style>` and `<script>`, no external assets, no
  storage APIs of any kind. Filter and sort state reset on load, deliberately -
  a `decide` row hidden by yesterday's filter is the failure this exists to
  prevent. A *fixed* default is not that failure and is the opposite of it: it
  is identical on every load, so nothing depends on what anyone clicked last
  time. Closed rows are out by default on those grounds - the register is a
  working control record first and an audit trail second, and what is still
  open has to be readable without scrolling past what is finished.
- When the filter leaves nothing visible, `#hint` says which state that is -
  an empty register or an over-narrow filter - and, when everything is simply
  finished, which chip to press. Every register reaches that state eventually:
  the last row closes and the default hides it. A blank table with no
  explanation reads as breakage, not as an answer.
- Action chips narrow, status chips widen. `show resolved` and `show
  superseded` add rows back rather than filtering down to them, and they are
  labelled with that effect - a chip reading `resolved` next to one reading
  `decide` implies the two do the same thing to the table, and they do not.
  `hide blocked` and `hide blocked epics` subtract, and say so.
- **No `<a href>` for internal navigation**, not even a pure fragment. The host
  page intercepts anchor clicks before the frame can cancel them, so
  `preventDefault()` does not help. Use `<button type="button">`.
- Interactive controls carry a word, not a glyph alone. A bare caret is not
  findable - which is why the copy button says `copy`, and says
  `select + copy` when the clipboard is unavailable rather than failing quietly.
- **The page cannot talk back.** Rendered in an embedded frame it has no
  `sendPrompt` and no async clipboard permission - measured, not assumed - so a
  button can never close a row by itself. Verdict buttons queue a line in the
  outbox instead; `document.execCommand` still works there and is what
  `copy all` falls back to. One basket rather than a button per row, because
  the clipboard holds one value - per-row copying breaks the moment two rows
  are open.
- A row offering named alternatives declares them - `data-choices="A|B"` on the
  `tr` - and gets one button per choice instead of agree/disagree, emitting
  `choose #n A`. Never author the buttons; the script generates them from the
  attribute, as it does every other control.
- Verdict verbs match their buttons: `agree #n` / `disagree #n -` on `decide`
  and `agent`, `applied #n` on `exec`, `accepted #n` / `rejected #n -` on
  `review`, `understood #n` on `ack`. `paste` gets none - what closes it is the
  pasted output itself. `agent` gets no closing button: agreeing approves the
  specification, and the row becomes a `review` when the output lands.
- Colour never carries meaning alone; the text label always stays.

## Details

Structure of the template, the verdict/outbox mechanics, cross-references,
block-level blocking, line numbers, the full colour and dimming rules and the
mobile layout: see [REFERENCE.md](REFERENCE.md).
