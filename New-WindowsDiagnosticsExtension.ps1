[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$VMName,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$StorageAccountName,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$SasToken,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ResourceGroupName
)

$params = @{
  vmName                 = $VMName
  storageAccountName     = $StorageAccountName
  storageAccountSasToken = $SasToken
}

New-AzResourceGroupDeployment -ResourceGroup $ResourceGroupName -TemplateFile "$PSScriptRoot/arm-templates/windowsVmDiagnostics.json" -TemplateParameterObject $params
