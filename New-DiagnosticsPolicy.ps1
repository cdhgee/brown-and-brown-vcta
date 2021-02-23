[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ManagementGroupId,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$StorageAccount,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$TagName,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string[]]$TagValue,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$Location
)

$params = @{
  storageAccount    = $StorageAccount
  tagName           = $TagName
  tagValue          = $TagValue
  managementGroupId = $ManagementGroupId
}

$policyDefinitions = @(
  @{
    Name        = "vcta-diagnostics-windows"
    DisplayName = "Enable diagnostic setting collection on Windows VMs for the Secureworks vCTA"
    Description = "This policy deploys the Azure diagnostics extension to Windows VMs matching a specific tag-value pair, to enable log collection in Secureworks using the vCTA"
    Mode        = "All"
  }
  @{
    Name        = "vcta-diagnostics-nsg"
    DisplayName = "Enable NSG flow log collection for the Secureworks vCTA"
    Description = "This policy enables NSG flow logs, to be sent to Secureworks using the vCTA"
    Mode        = "All"
  }
)

Foreach ($def in $policyDefinitions) {

  New-AzPolicyDefinition `
    -Policy "$PSScriptRoot/policy-definitions/$($def.Name).json" `
    -Parameter "$PSScriptRoot/policy-definitions/$($def.Name)-parameters.json" `
    -Metadata "$PSScriptRoot/policy-definitions/$($def.Name)-metadata.json" `
    -ManagementGroupName $ManagementGroupId `
    @def

}

$policySetName = "vcta-diagnostics"
$policySetDisplayName = "Enable diagnostic setting collection for the Secureworks vCTA"
$policySetDescription = "This policy initiative enables diagnostic log collection for VMs and other resources that is sent to Secureworks via the Azure vCTA" `

$setDefinition = (Get-Content -Path "$PSScriptRoot/policy-set-definitions/vcta-diagnostics.json" -Encoding utf8 -Raw) -replace "--MGID--", $ManagementGroupId

New-AzPolicySetDefinition `
  -Name $policySetName `
  -DisplayName $policySetDisplayName `
  -Description $policySetDescription `
  -PolicyDefinition $setDefinition `
  -Parameter "$PSScriptRoot/policy-set-definitions/vcta-diagnostics-parameters.json" `
  -Metadata "$PSScriptRoot/policy-set-definitions/vcta-diagnostics-metadata.json" `
  -ManagementGroupName $ManagementGroupId

$psd = Get-AzPolicySetDefinition -Id "/providers/Microsoft.Management/managementGroups/$ManagementGroupId/providers/Microsoft.Authorization/policySetDefinitions/$policySetName"

$policySetParams = @{
  storageAccount = $StorageAccount
  tagName        = $TagName
  tagValue       = $TagValue
}

New-AzPolicyAssignment `
  -Name $policySetName `
  -DisplayName $policySetDisplayName `
  -Description $policySetDescription `
  -PolicySetDefinition $psd `
  -PolicyParameterObject $policySetParams `
  -Metadata "$PSScriptRoot/policy-set-definitions/vcta-diagnostics-metadata.json" `
  -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupId" `
  -AssignIdentity `
  -Location $Location

$ass = Get-AzPolicyAssignment -Id "/providers/Microsoft.Management/managementGroups/$ManagementGroupId/providers/Microsoft.Authorization/policyAssignments/$policySetName"

$mgScope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"

$mgRoles = @(
  "Virtual Machine Contributor"
  "Network Contributor"
)

Foreach ($role in $mgRoles) {

  New-AzRoleAssignment `
    -ObjectId $ass.Identity.principalId `
    -Scope $mgScope `
    -RoleDefinitionName $role

}

New-AzRoleAssignment `
  -ObjectId $ass.Identity.principalId `
  -Scope $StorageAccount `
  -RoleDefinitionName "Reader and Data Access"

