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
  [string[]]$TagValue
)

$params = @{
  storageAccount    = $StorageAccount
  tagName           = $TagName
  tagValue          = $TagValue
  managementGroupId = $ManagementGroupId
}

New-AzManagementGroupDeployment -ManagementGroupId $ManagementGroupId `
  -TemplateFile "$PSScriptRoot/arm-templates/deploy-vcta-diagnostics.json" `
  -TemplateParameterObject $params
