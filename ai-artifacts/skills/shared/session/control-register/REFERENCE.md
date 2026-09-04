# Reference

## Template anatomy

`assets/template.html` is a complete, working file with two placeholder rows.
Four regions:

| region                   | change it?                                              |
| ------------------------ | ------------------------------------------------------- |
| `<style>`                | only when changing the rendering itself                 |
| control strip (`#bar`)   | no - chips are generated from the rows present          |
| `<colgroup>` + `<tbody>` | every turn; widths carry forward if the user edits them |
| `<script>`               | only when changing the rendering itself                 |

`scripts/verify.js` takes the register, and optionally the previous version of
it as a second argument. With the second file it also reports details that have
gone missing - the only failure here that cannot be seen in the file being
checked, because a dropped detail leaves nothing behind. It loads a rendered
block and asserts what the markup cannot show: row pairing, action class against action text, blockers pointing at real
IDs, epic membership and header counts, copy buttons, filter round-trip. It
needs `jsdom`. It works on the template and on any generated register.

`<table id="grid" data-tpl="...">` carries the template version, and the
verifier compares it against its own constant. That stamp is why a stale
register fails on one comparison instead of on whichever feature sniff someone
remembered to write - a register that verifies clean against a template it was
not built from is the failure this replaces.

Column widths default to `5 / 21 / 9 / 29 / 36`. They are percentages on
`<col>` elements with `table-layout: fixed`, so content cannot override them -
which is the point. Under 700px the whole table switches to `display: block`
and `<colgroup>` is ignored.

## Row markup

```html
<tr class="ACTION[ resolved|superseded][ has-detail]">
  <td class="id">N</td>
  <td>item</td>
  <td class="act">ACTION[<span class="mark">✅</span>][<span class="blocked">blocked by #N</span>]</td>
  <td>recommendation</td>
  <td>rationale</td>
</tr>
```

The action appears twice - as the row class, which drives sorting, filtering
and colour, and as visible text in the action cell. They must agree.

`has-detail` is a readability marker only; the script pairs rows by position,
not by that class. It still goes on the row, because a detail row whose
predecessor lacks the marker is the visible symptom of a mis-ordered pair.

A detail row is `<tr class="detail" hidden><td colspan="5">…</td></tr>` and
carries `<h3>` headings plus prose, lists, or `<pre><code>` blocks. Keep the
`hidden` attribute in the source: the script manages it from there, and a
detail left visible in the markup is a detail the toggle button then closes on
first click.

## Epics

An epic is an authored header row followed by the rows that belong to it.
Membership is position: everything after a `tr.epichead` up to the next one, or
to the end of the table.

```html
<tr class="epichead"><td colspan="N">
  <span class="ename">…</span>[<span class="model">…</span>]<span class="gcount">…</span>
  <button type="button" class="toggle gtoggle">hide</button>
</td></tr>
```

- The header cell spans every column, so its `colspan` tracks the number of
  `<th>` elements. The collapse button floats right; it is the only control in
  the block, so the right edge is where it can be found without hunting.
- `.gcount` is open rows per action in rank order joined with ` · `, or
  `N rows, all closed`. It is written by hand and therefore the one thing here
  that can silently disagree with reality - `scripts/verify.js` recomputes it
  and fails on drift.
- A block runs to the next `tr.epichead` or to the end of the table.
  `<tr class="blockend" hidden>` ends one early, which is what lets an urgent
  block be written at the top with loose rows below it. It renders nothing and
  is only needed where a block would otherwise swallow what follows.
- Rows in a headed block get a generated `inepic` class that draws an accent
  down the left edge. That marker is what ends the block: without it, the first
  row after the last member reads as one of them, which is the one epic bug
  that looks correct on screen.
- Sorting reorders rows **within** each partition and never across a header,
  because a header holds its position. `#hint` says `sorted within each block`
  whenever a sort is active and headers are present - otherwise the column
  arrow implies a global order the table does not have.
- Block order is authorial, with one exception: a block whose rows are all
  closed sorts after every block that still has an open row. Nothing floats an
  epic *up* - ranking blocks by their best open action would let one jump the
  queue for acquiring a single `decide`, and the order would stop being yours.
  Demotion is safe in a way promotion is not, because a block with nothing open
  has nothing to say. The rows before the first header are a partition too, and
  they are the case this exists for: they sit first by construction rather than
  by choice, so a handful of resolved rows would otherwise push the first real
  epic off the top of the screen.
- Blocks are still written most urgent first, and the `decide` chip stays the
  reliable way to find decisions wherever they sit.
- Header text is folded into each member's free-text index, so typing the epic
  name filters to the block.

An epic is not an action. The action column answers "what does this need from
me" and every member row still answers it; a row whose action read `epic` would
stop saying whether the work is blocked on a decision or ready to run.

## Copy buttons

Every `<pre>` inside a detail row is wrapped in `div.codeblock` and given a
`copy` button, injected by the script - never authored.

- Injection happens after `dataset.text` is built, so the button label never
  enters the free-text index.
- `navigator.clipboard.writeText` is tried first and falls back to
  `execCommand` on a detached textarea, because clipboard access is blocked in
  some embedded frames.
- If both fail the button says `select + copy` and selects the block, rather
  than reporting a success it did not achieve.
- The copied text is `pre.textContent` verbatim, with no trailing newline
  added: a trailing newline pasted into a shell runs the command before it can
  be read.

## What the script does

- Pairs each row with the detail row that follows it, if any.
- Injects the `details` / `hide` toggle button into the item cell of every
  `has-detail` row, with `aria-expanded`.
- Builds one filter chip per action and per status actually present, with a
  live count. The two kinds do opposite things, which is why the status ones
  are labelled `show resolved` / `show superseded`:
  - **action chips narrow.** None pressed means every action; pressing some
    restricts to those.
  - **status chips widen.** None pressed means open rows only; pressing one
    adds that closed status back alongside them.
  The two gates are independent, so `show resolved` + `agent` reads as "the
  agent rows, including the finished ones".
- The row count reports `N open, M closed` when the default is in force. Saying
  `N of M shown` there would imply the reader had filtered something out.
- Sorts: default is open-before-closed, then action rank (`decide` > `paste` >
  `exec` > `ack`), then ID ascending, applied inside each partition. Clicking
  `ID` or `action` cycles ascending -> descending -> back to default, so a sort
  is always escapable.
- Free-text filter searches the row, its epic header, *and* its collapsed
  detail text.
- Partitions rows by authored headers, sorts within each, marks members, wires
  collapse, and writes the sort hint; generates the copy button on every detail
  code block.

Adding a new action value means four edits, not three: `RANK` in the script, a
colour rule, a chip border colour, and the `ACTIONS` constant in
`scripts/verify.js`. The chip itself is automatic.

The fourth is the one that gets missed, and it does not break rendering. It
makes the verifier report `#N carries 0 action classes` for every row using the
new action - a failure that reads as bad markup in the register, so it gets
debugged in the wrong file.

## Colour and dimming

| action   | colour | row tint              |
| -------- | ------ | --------------------- |
| `decide` | red    | faint, open rows only |
| `paste`  | amber  | faint, open rows only |
| `exec`   | blue   | none                  |
| `agent`  | violet | none                  |
| `ack`    | green  | none                  |

Status is orthogonal to action. `resolved` and `superseded` dim the three text
columns and drop the tint; `superseded` also italicises the action.

Dark-scheme variants are declared for each. Two things are never dimmed:

- the `ID` column, on any row state - a dimmed ID is unreadable at the size it
  is set, and the ID is how rows are referenced
- blocked rows - the blocker line is the thing most needing to be read, so
  muting the row buries it

Closed rows dim their three text columns only, via
`tr.resolved td:not(.id):not(.act)` and the matching `tr.superseded` rule.

## Mobile

Under 700px the table becomes stacked cards: `thead` hidden, each `td` a block,
the ID prefixed with `#` and bolded as the card heading. The toggle button
grows its padding to a thumb-sized target. Epic headers keep their `colspan` td
as a block; the model badge and counts wrap onto their own line and the collapse
button becomes full-width. Copy buttons stay pinned to the top right of the
block and grow their tap target. Test any rendering change at both
widths - the desktop layout hides mobile breakage completely.

## Verdict buttons and the outbox

The page is rendered in an embedded frame with no `sendPrompt` and no async
clipboard permission - measured, not assumed. A button therefore cannot close a
row; it can only prepare text for the reader to paste.

- One button set per action, generated from `VERDICTS`: `decide` and `agent`
  get agree/disagree, `exec` gets `applied`, `ack` gets `understood`, `paste`
  gets none. Closed rows get none.
- A row that declares `data-choices="A|B|C"` replaces that pair with one button
  per choice, emitting `choose #n A`. Agreeing to "A or B" names neither, so
  the choices themselves have to be the buttons. The separator is `|`; two
  choices is the minimum, and `scripts/checks.js` rejects an empty, repeated or
  single choice, and any choice list on a closed row.
- A row whose recommendation cell ends in a question mark is rejected. The
  recommendation is where the answer goes; a question there leaves every button
  meaningless, because there is nothing stated to agree with. Either state the
  recommendation or declare the choices.
- A click queues one line in `#outbox`, keyed by ID, sorted by ID so the block
  reads in register order rather than in click order. Clicking the same button
  again removes the line.
- `disagree` emits a trailing `-` and stops. A disagreement without a reason
  is not a decision, so the line is deliberately unfinished.
- Queuing a verdict collapses that row's detail; un-queuing does not reopen it,
  because taking a verdict back is when the reasoning is wanted back on screen.
- One basket, not a copy button per row: the clipboard holds a single value, so
  per-row copying stops working the moment two rows are open.
- `copy all` uses the same fallback chain as the code blocks and ends at
  `select + copy`. `clear` also resets the textarea's inline height, which a
  manual resize would otherwise leave behind as a tall empty box.
- The outbox sits in `#top`, right of the title, at `clamp(20rem, 33vw, 50vw)`,
  and is dimmed while empty. It is in the flow, not over it: `#top` is
  `position: sticky`, so the outbox is always on screen without ever covering
  a row. Nothing reserves space for it and nothing measures it - an outbox that
  overlaps nothing cannot need either.
- `#outbox.empty` keeps `pointer-events: none`. In the sticky header it changes
  nothing, because the outbox overlaps no control. It is the one line that has
  to come back first if the outbox is ever floated again.
- `#top` caps at `55vh` and scrolls inside itself. Without the cap a narrow
  frame renders as header with a sliver of table under it: the chips alone
  wrap to four rows at 380px.

## Cross-references

Every `#n` in prose that matches a row in the register becomes a `button.jump`
on load. Text inside `<code>`, `<pre>`, an existing button, the ID cell or the
action cell is skipped, so a literal `#12` in a snippet stays text. A reference
to a row that is not present stays plain text as well - visibly not a control,
rather than a button that goes nowhere.

Never author the button. `scripts/verify.js` fails on a `data-goto` or
`data-goto-epic` that names nothing.

A jump lifts whatever is hiding its target first - filters, the search box, a
collapsed block, and the status chip if the target is closed - then scrolls and
flashes it. Without that it would land on a hidden row and read as dead.

## Blocking a whole block

An epic can be blocked as a unit, which is the honest shape when the dependency
is between phases rather than between two rows:

```html
<tr class="epichead isblocked" data-epic="skill"><td colspan="5">
  <span class="ename">Phase 2 - …</span><span class="gcount">1 exec</span>
  <button type="button" class="toggle gtoggle">hide</button>
  <span class="blocked">blocked by <button type="button" class="jump"
    data-goto-epic="instr">Phase 1 - …</button></span>
</td></tr>
```

The amber bar runs down every member row via a generated `inblockedepic` class,
so the state is readable on a row whose header has scrolled off. `hide blocked
epics` is a separate chip from `hide blocked` on purpose: the row-level filter
would leave the members of a blocked block on screen, each individually
unblocked and none of them actionable.

## Line numbers

Each line of a detail `<pre>` is wrapped in `span.ln` and numbered by a CSS
counter. The number is never a text node: `pre.textContent` is what the copy
button reads, so a number in the markup would be copied along with the code.
Syntax highlighting is deliberately absent - a tokenizer per language inside a
self-contained file with no CDN, against numbering that already carries most of
the readability.
