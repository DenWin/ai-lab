---
name: prototype
description: Build a throwaway prototype to flesh out a design before committing to it. Build a tiny interactive terminal app that drives a state model, data shape, command surface, or output format by hand — pushing it through cases that are hard to reason about on paper. Use when the user wants to prototype, sanity-check a data model or state machine, feel out an API/cmdlet surface or SQL schema, explore an idea, or says "prototype this", "let me play with it", "does this shape feel right".
upstream-author: mattpocock
upstream-repo: https://github.com/mattpocock/skills
upstream-path: skills/engineering/prototype/SKILL.md
upstream-commit: aaf2453fbdfe7a15c07f11d861224f34ab4b53cb
---

# Prototype

A prototype is **throwaway code that answers one question**. The question decides the shape.

This skill builds a small interactive terminal app that lets the user drive a model by hand — the kind of thing that looks reasonable on paper but only feels wrong once you push it through real cases. Use it when the question is about **business logic, state transitions, data shape, a command/cmdlet surface, or an output/schema layout**.

Typical questions it answers:

- "I'm not sure this state machine handles X then Y."
- "Does this data model actually let me represent the case where...?"
- "I want to feel out what this API / cmdlet parameter surface should look like before writing it."
- "Does this SQL schema shape hold up once I push some rows through it?"
- Anything where the user wants to **press keys and watch state change**.

## Rules (non-negotiable)

1. **Throwaway from day one, and marked as such.** Put it next to the module it's prototyping for so context is obvious, but name it so a casual reader sees it's a prototype, not production (`proto-<thing>.ps1`, `Proto<Thing>/`, `proto_<thing>.py`).
2. **One command to run.** Via the project's existing task runner or a single documented invocation — `pwsh ./proto-<thing>.ps1`, `dotnet run --project Proto<Thing>`, `python proto_<thing>.py`. The user starts it without thinking. Don't add a new runtime or package manager just for the prototype.
3. **No persistence by default.** State lives in memory. Persistence is usually the thing being _checked_, not depended on. If the question is specifically about persistence, hit a scratch target with an obvious throwaway name (`tempdb` table `Proto_WipeMe`, a `proto-wipe-me.db`), never a real one.
4. **Skip the polish.** No tests, no abstractions, no error handling beyond what makes it runnable. The point is to learn fast and delete.
5. **Surface the state.** Re-render the full relevant state after every action so the user sees exactly what changed.
6. **Delete or absorb when done.** Once it has answered its question, fold the validated decision into the real code or delete it — don't leave it rotting in the repo.

## Process

### 1. State the question

Before any code, write down the model and the question in one paragraph — top-of-file comment, or a `NOTES.md` next to the prototype. A prototype that answers the wrong question is pure waste; make the question explicit so it can be checked later, whether the user is watching now or returning to it AFK.

### 2. Pick the language

Use whatever the host project uses. With no obvious host runtime, default by question type: **pwsh 7** for quick infra/state poking, **C#** when the state model wants real types and you'll lift the logic into a typed codebase, **Python** for fast iteration on data shapes. Match the project's existing tooling — don't introduce a new one.

### 3. Isolate the logic in a portable, pure module

The bit that answers the question goes behind a small **pure** interface that could be lifted into the real codebase later. The TUI around it is throwaway; the logic module is the thing worth keeping. No I/O, no terminal codes, no logging-for-control-flow inside it. The TUI imports it and calls in; nothing flows the other way.

Pick the shape that fits the question, not the one easiest to wire to a TUI:

- **A pure reducer** — `(state, action) -> state`. Best when actions are discrete events over a single state value.
- **A state machine** — explicit states and legal transitions. Best when "which actions are even legal right now" is part of the question.
- **A set of pure functions** over a plain data type. Best when there's no implicit current state — just transformations.
- **A class/module with a clear method surface** when the logic genuinely owns ongoing internal state.

Stack-specific notes:

- **pwsh 7** — pure logic as a function or a small dot-sourced module returning new state (`function Invoke-ProtoAction { param($State, $Action) ... ; $newState }`); treat `[pscustomobject]` / hashtable state as immutable, return a fresh copy. `$ErrorActionPreference = 'Stop'` at the top. No `Write-Host`; the TUI handles rendering, the logic module stays silent.
- **C#** — `record` for state, a single `Reduce(State, Action)` static method or a small state-machine class. The TUI (`Console.*`) is a separate file from the logic type so the type drops into the real project untouched.
- **Python** — `@dataclass(frozen=True)` state + a pure `reduce(state, action) -> State`, or plain functions over a `dataclass`. Keep `input()` / escape codes out of the logic module.
- **Output/command-surface or SQL-schema questions** — the "state" is the candidate shape itself (a parameter set, a row layout, a result projection). The TUI lets the user apply sample inputs/rows and re-renders how that shape reads. For SQL, build the shape against a scratch `tempdb` object and project rows through it; never touch real tables.

### 4. Build the smallest TUI that exposes the state

A lightweight redraw loop — on every tick, clear the screen and re-render the whole frame, so the user always sees one stable view, not growing scrollback.

- Clear: pwsh `[Console]::Clear()` (or `Clear-Host`); C# `Console.Clear()`; Python `print("\x1b[2J\x1b[H", end="")`.
- Native ANSI is fine for emphasis — `\x1b[1m` bold, `\x1b[2m` dim, `\x1b[0m` reset. No styling library unless the project already has one.

Each frame, in this order:

1. **Current state**, diff-friendly — one field per line or formatted JSON. **Bold** field names/headers, **dim** less-important context (timestamps, IDs, derived values).
2. **Keyboard shortcuts** at the bottom: `[a] add  [d] delete  [t] tick  [q] quit`. Bold the key, dim the description.

Loop: initialise a single in-memory state object and render the first frame → read one keystroke/line → dispatch to a handler that produces the next state via the pure module → re-render the full frame → repeat until quit. The whole frame fits on one screen.

### 5. Make it runnable in one command

Add it to the project's existing task runner if there is one (`*.psd1`/build script, `Makefile`, `justfile`, `pyproject.toml` script, a `.NET` launch profile). Otherwise put the single invocation at the top of the prototype's notes. The user runs one command, never a remembered path.

### 6. Hand it over

Give the run command. The user drives it; the valuable moments are "wait, that shouldn't be possible" or "huh, I assumed X would differ" — those are bugs in the _idea_, which is the whole point. If they want new actions, add them. Prototypes evolve.

### 7. Capture the answer

The answer is the only thing worth keeping. If the user is around, ask what it taught them. If AFK, leave a `NOTES.md` next to the prototype recording the question and the verdict, so it can be filled in before the prototype is deleted (a top-of-file comment is fine for a one-liner; reach for AsciiDoc only if the notes grow into real extended documentation). Then fold the validated reducer/machine/function-set into the real module and delete the TUI shell.

## Anti-patterns

- **Don't add tests.** A prototype that needs tests is no longer a prototype.
- **Don't wire it to a real database.** In-memory unless the question is specifically about persistence — then a clearly-named scratch target.
- **Don't generalise.** No "what if we wanted to support X later." It answers one question.
- **Don't blur the logic and the TUI together.** If the reducer/machine references `Read-Host`, `Console.ReadKey`, `input()`, or escape codes, it's no longer portable. The TUI is a thin shell over a pure module.
- **Don't promote the TUI shell to production.** The shell is built to be driven by hand from a terminal under prototype constraints (no tests, minimal error handling). Lift the logic module; rewrite anything else properly.
