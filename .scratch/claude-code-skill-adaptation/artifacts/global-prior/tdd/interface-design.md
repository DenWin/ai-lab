# Interface Design for Testability

Good interfaces make testing natural:

1. **Keep external calls in named functions — Pester mocks by name**

   In PowerShell, Pester's `Mock` replaces any function by name within the test scope. You don't need to pass dependencies as parameters. What matters is that the external call happens through a clearly named function, not inline logic:

   ```powershell
   # Testable — Pester can Mock 'Invoke-StripeCharge' by name
   function Invoke-Order {
       param($Order)
       Invoke-StripeCharge -Amount $Order.Total
   }

   # Harder to test — boundary is an anonymous Invoke-RestMethod call
   function Invoke-Order {
       param($Order)
       Invoke-RestMethod -Uri 'https://api.stripe.com/charge' -Body @{ amount = $Order.Total }
   }
   ```

2. **Return results, don't only produce side effects**

   ```powershell
   # Testable — result is explicit, assertion is simple
   function Get-Discount {
       param([decimal]$CartTotal, [string]$PromoCode)
       # ...
       return $discountAmount
   }

   # Harder to test — mutates via [ref], no return value to assert on
   function Apply-Discount {
       param([ref]$Cart, [string]$PromoCode)
       $Cart.Value.Total -= $discount
   }
   ```

3. **Small surface area**
   - Fewer parameters = simpler test setup
   - Fewer responsibilities per function = fewer test cases needed
