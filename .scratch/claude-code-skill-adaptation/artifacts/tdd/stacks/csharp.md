# Stack Rules: C# / .NET

- Default to xUnit + FluentAssertions for new work unless the codebase uses
  something else. FluentAssertions gives far better failure messages, and most
  test-reading time is spent on failures.
- Use Moq or NSubstitute with **loose mocks** by default. Strict mocks fail on
  unexpected calls, coupling the test to the exact call sequence.
- Never use `.Result` or `.Wait()` in tests — they can deadlock and obscure
  exceptions. Test methods return `Task` and `await`. Use
  `Assert.ThrowsAsync<T>` or `await act.Should().ThrowAsync<T>()` for async
  exceptions; the non-async forms silently miss exceptions thrown after the
  first await.
- Do not test against the EF Core `InMemory` provider as a substitute for the
  real database — case sensitivity, transactions, query translation, and
  concurrency tokens all differ. Use the SQLite in-memory provider where the
  dialect is close enough, or Testcontainers where dialect matters.
- Inject `TimeProvider` (modern .NET) or an `IClock`. Never call `DateTime.Now`
  in testable code.
- Set culture explicitly in tests. Do not rely on `CurrentCulture` defaults.
- Do not use `InternalsVisibleTo` to test internals. If you need to, the public
  API is wrong or the internals belong in their own testable type.
- Wrap `HttpClient`, `DbContext`, `IConfiguration` in owned interfaces before
  mocking. Do not mock them directly.
- Do not over-use `[Theory]`/`[InlineData]` for tests that verify genuinely
  different behaviors — those want separate `[Fact]` methods.
- Use `WebApplicationFactory` for integration tests of controllers, middleware,
  and the request pipeline. Do not unit-test controllers with a mocked DI
  container — that verifies DI registration, not behavior.
