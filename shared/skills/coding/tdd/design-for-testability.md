# Design for Testability

Good interfaces make tests natural. Stack-neutral; apply in any language.

## Accept Dependencies, Don't Create Them

Pass external dependencies in rather than constructing them inside the unit.
A function that news-up its own database client, HTTP client, or clock cannot
be tested without the real thing. A function that receives them can be tested
with a fake or stub. This is the single highest-leverage testability change.

## Return Results, Don't Mutate Hidden State

Prefer functions that return a value over functions that mutate a shared object
or produce side effects. A computed return value is trivial to assert on; a
buried mutation forces the test to reach in and inspect state — which couples it
to internals.

## Deep Modules, Small Surface

Prefer a **small interface over a deep implementation** to a large interface
over a thin one. Fewer public methods and simpler parameters mean fewer tests,
simpler setup, and more freedom to refactor internals without touching tests.
When designing an interface, ask: can I reduce the number of methods? Simplify
the parameters? Hide more complexity inside?

A shallow module (large interface, little behind it) leaks its internals into
every caller and every test, and is the thing to combine or deepen during the
refactor step.

## Consequence for Mocking

Interfaces designed this way are also the right things to mock: an owned
abstraction with a small surface gives the test one clear seam at a real
boundary, instead of many incidental seams at internal function calls. See
[test-doubles.md](test-doubles.md).
