# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```powershell
# GOOD: Tests observable behavior
Describe 'Invoke-Deployment' {
    It 'returns Succeeded status when template deploys cleanly' {
        $result = Invoke-Deployment -ResourceGroup 'rg-prod' -TemplatePath '.\template.bicep'
        $result.ProvisioningState | Should -Be 'Succeeded'
    }
}
```

Characteristics:

- Tests behavior callers care about
- Uses public function signature only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```powershell
# BAD: Tests implementation details — verifies a call was made, not the outcome
Describe 'Invoke-Deployment' {
    It 'calls New-AzResourceGroupDeployment' {
        Mock New-AzResourceGroupDeployment {}
        Invoke-Deployment -ResourceGroup 'rg-prod' -TemplatePath '.\template.bicep'
        Should -Invoke New-AzResourceGroupDeployment -Times 1
    }
}
```

Red flags:

- Mocking internal collaborators
- Asserting on call counts/order rather than return values or state
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of the public interface

```powershell
# BAD: Bypasses interface to verify — queries the DB directly
It 'inserts user into database' {
    Add-AppUser -Name 'Alice'
    $row = Invoke-Sqlcmd -Query "SELECT * FROM Users WHERE Name = 'Alice'" -ServerInstance $TestDb
    $row | Should -Not -BeNullOrEmpty
}

# GOOD: Verifies through interface — uses the same functions a caller would use
It 'makes user retrievable after creation' {
    Add-AppUser -Name 'Alice'
    $user = Get-AppUser -Name 'Alice'
    $user.Name | Should -Be 'Alice'
}
```
