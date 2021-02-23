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

$policyDir = "$PSScriptRoot/policy-definitions"
$policySetDir = "$PSScriptRoot/policy-set-definitions"

$policyDefinitions = Get-ChildItem -Path $policyDir -Filter "*.json"

Foreach ($policyFile in $policyDefinitions) {

  $definition = Get-Content -Path $policyFile.FullName -Encoding utf8 `
  | ConvertFrom-Json -Depth 100

  $pieces = @{
    Policy              = $definition.properties.policyRule | ConvertTo-Json -Depth 100
    Parameter           = $definition.properties.parameters | ConvertTo-Json -Depth 100
    Metadata            = $definition.properties.metadata | ConvertTo-Json -Depth 100
    ManagementGroupName = $ManagementGroupId
    Name                = $definition.name
    DisplayName         = $definition.properties.displayName
    Description         = $definition.properties.description
    Mode                = $definition.properties.mode
  }

  New-AzPolicyDefinition @pieces

}

$policySetName = "vcta-diagnostics"
$policySetDisplayName = "Enable log collection for the Secureworks vCTA"
$policySetDescription = "This policy initiative enables diagnostic log collection for VMs and other resources that is sent to Secureworks via the Azure vCTA" `

$setDefinition = (Get-Content -Path "$policySetDir/vcta-diagnostics.json" -Encoding utf8 -Raw) -replace "--MGID--", $ManagementGroupId

New-AzPolicySetDefinition `
  -Name $policySetName `
  -DisplayName $policySetDisplayName `
  -Description $policySetDescription `
  -PolicyDefinition $setDefinition `
  -Parameter "$policySetDir/vcta-diagnostics-parameters.json" `
  -Metadata "$policySetDir/vcta-diagnostics-metadata.json" `
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
  -Metadata "$policySetDir/vcta-diagnostics-metadata.json" `
  -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupId" `
  -AssignIdentity `
  -Location $Location

$ass = Get-AzPolicyAssignment -Id "/providers/Microsoft.Management/managementGroups/$ManagementGroupId/providers/Microsoft.Authorization/policyAssignments/$policySetName"

$mgScope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"

$mgRoles = @(
  "Monitoring Contributor",
  "Network Contributor",
  "Virtual Machine Contributor"
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

