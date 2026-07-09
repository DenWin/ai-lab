# Test Double Selection

- **Mock at trust boundaries, not at function calls.** Do not mock a
  collaborator just because it is a separate function or class. If the inner
  code is pure logic you own and part of the same behavior, let it run —
  mocking it tests structure, not behavior.

  ```python
  def outer(n):
      a = inner_a(n)   # owned, pure, same behaviour → DO NOT mock
      b = inner_b(a)   # let them run; assert on outer()'s result
      return a + b
  ```

- The above is the **classicist** default. A stricter discipline exists —
  "never mock anything I own; mock only external dependencies" — and some teams
  adopt it deliberately (heavily message-based architectures, strict
  ports-and-adapters projects, London-school style). If my code, existing tests,
  or stated preference indicate I am working in that stricter style, propose it
  explicitly, name it, and explain the trade-off (more brittleness under
  interaction-level refactor in exchange for stricter decoupling of owned
  components). Do not silently mix the two styles in one suite.
- **Wrap third-party libraries in a thin abstraction you own.** Mock the
  abstraction, not the library directly.
- When the wrapper handles more than one operation, give each operation its own
  method (SDK-style). Do not propose a single generic `request(operation,
  payload)` dispatcher — it reintroduces the same generality leak that wrapping
  was supposed to remove.

  ```python
  # SDK-style: each method mocks to one shape, no conditional mock logic
  client.send(msg); client.cancel(id); client.get_status(id)
  # vs generic dispatcher — mock must branch on operation:
  client.request("send", {...})
  ```

- **Stub** when the test cares about the resulting value. **Mock** only when
  the interaction itself is the user-visible behavior.
- **Fake** (in-memory implementation) is preferred over mock when the
  collaborator has stateful behavior that affects multiple test steps.
- Never mock standard-library types (strings, collections, basic I/O
  primitives) unless there is a specific reason.
- Do not propose mocks for code at the edges (I/O, UI, network) without first
  proposing an abstraction layer to mock against.

## Double Taxonomy (Meszaros)

| Kind | Purpose |
| --- | --- |
| Dummy | Fills a parameter slot; never used. |
| Stub | Returns canned answers. Use when the code needs specific inputs from a collaborator. |
| Spy | A stub that records how it was called. Use when verifying an interaction occurred. |
| Mock | A spy with pre-set expectations; fails if they are not met. Strictest. |
| Fake | A working but production-unsuitable implementation (in-memory DB/queue). |

Using a mock where a stub would do creates over-specified tests that fail on
irrelevant changes. Using a stub where a mock is needed leaves interaction bugs
unverified.
