[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$StorageAccountName,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ResourceGroupName

)

$context = (Get-AzStorageAccount -AccountName $StorageAccountName -ResourceGroupName $ResourceGroupName).context

# Midnight UTC yesterday - to account for timezone differences
$startDate = [datetime]"$([datetime]::Today.AddDays(-1).ToString("yyyy-MM-dd")) 00:00:00Z"
$endDate = $startDate.AddYears(30)

$token = New-AzStorageAccountSASToken -Context $context -Service @("Blob", "Table") -ResourceType @("Container", "Object") -Permission "acuw" -Protocol HttpsOnly -StartTime $startDate -ExpiryTime $endDate
$token.Substring(1)
