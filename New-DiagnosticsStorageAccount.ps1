[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$StorageAccountName,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ResourceGroupName,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$Location,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ServiceAccountUPN
)

$params = @{
  storageAccountName = $StorageAccountName
}

$rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

New-AzResourceGroupDeployment -ResourceGroup $ResourceGroupName -TemplateFile "$PSScriptRoot/arm-templates/diagnosticsStorageAccount.json" -TemplateParameterObject $params

$user = Get-AzADUser -UserPrincipalName $ServiceAccountUPN
$role = Get-AzRoleDefinition -Name "Reader and Data Access"

New-AzRoleAssignment -Scope $rg.ResourceId -ObjectId $user.Id -RoleDefinitionId $role.Id
