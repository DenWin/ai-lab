# When to Mock

Mock at **system boundaries** only:

- External APIs (Azure, REST services, etc.)
- Databases (prefer a test DB when practical; mock when integration setup is too heavy)
- Time/randomness
- File system (when side effects matter)

Don't mock:

- Your own functions/modules
- Internal helpers
- Anything you control

## Mocking in Pester

Pester's `Mock` command replaces any PowerShell function by name within a `Describe`/`It` scope. No dependency injection framework is needed. The design principle: keep external calls in clearly named functions so Pester can intercept them.

**Mock at the boundary**

```powershell
# Design: external call lives in one named function
function Submit-Payment {
    param([decimal]$Amount)
    Invoke-StripeCharge -Amount $Amount  # boundary — Pester can Mock this
}

# Test
Describe 'Submit-Payment' {
    It 'passes the amount to the payment provider' {
        Mock Invoke-StripeCharge { return @{ Status = 'succeeded' } }
        $result = Submit-Payment -Amount 99.99
        $result.Status | Should -Be 'succeeded'
    }
}
```

**Avoid burying the boundary inside inline logic** — Pester can still mock `Invoke-RestMethod`, but the test setup becomes fragile:

```powershell
# Harder to test — HTTP call is inline, mock must know the exact URI and parameters
function Submit-Payment {
    param([decimal]$Amount)
    $body = @{ amount = $Amount; currency = 'usd' } | ConvertTo-Json
    Invoke-RestMethod -Uri 'https://api.stripe.com/charge' -Method Post -Body $body
}
```

## Designing for Mockability

**Prefer specific functions per operation over generic dispatchers**

Create one function per external operation. Each is independently mockable and its return shape is explicit:

```powershell
# GOOD: each function is independently mockable
function Get-AzUserRecord  { param([string]$UserId)      <# GET /users/{id} #> }
function Get-AzUserOrders  { param([string]$UserId)      <# GET /users/{id}/orders #> }
function New-AzUserOrder   { param([hashtable]$OrderData) <# POST /orders #> }

# BAD: generic dispatcher — mocking requires conditional logic inside the mock
function Invoke-AzUserOperation {
    param([string]$Operation, [hashtable]$Params)
    # switch on $Operation ...
}
```

The specific-function approach means:
- Each mock returns one predictable shape
- No conditional logic in test setup
- Clear which external calls a test exercises
