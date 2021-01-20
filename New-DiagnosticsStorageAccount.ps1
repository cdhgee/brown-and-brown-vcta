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
  [string]$Location
)

$params = @{
  storageAccountName = $StorageAccountName
}

New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

New-AzResourceGroupDeployment -ResourceGroup $ResourceGroupName -TemplateFile "$PSScriptRoot/arm-templates/diagnosticsStorageAccount.json" -TemplateParameterObject $params
