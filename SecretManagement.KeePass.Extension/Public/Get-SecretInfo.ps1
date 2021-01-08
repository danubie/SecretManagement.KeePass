using namespace Microsoft.PowerShell.SecretManagement

function Get-SecretInfo {
    param(
        [string]$Filter,
        [string]$VaultName = (Get-SecretVault).VaultName,
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters
    )
    if (-not (Test-SecretVault -VaultName $vaultName)) {throw "Vault ${VaultName}: Not a valid vault configuration"}

    $KeepassParams = GetKeepassParams -VaultName $VaultName -AdditionalParameters $AdditionalParameters
    $KeepassGetResult = Get-KeePassEntry @KeepassParams | Where-Object {$_ -notmatch '^.+?/Recycle Bin/'}

    [Object[]]$secretInfoResult = $KeepassGetResult.where{ 
        $PSItem.Title -like $filter 
    }.foreach{
        [SecretInformation]::new(
            $PSItem.Title, #string name
            [SecretType]::PSCredential, #SecretType type
            $VaultName #string vaultName
        )
    }

    [Object[]]$sortedInfoResult = $secretInfoResult | Sort-Object -Unique Name
    if ($sortedInfoResult.count -lt $secretInfoResult.count) {
        $filteredRecords = (Compare-Object $sortedInfoResult $secretInfoResult | Where-Object SideIndicator -eq '=>').InputObject
        Write-Warning "Vault ${VaultName}: Entries with non-unique titles were detected, the duplicates were filtered out. Duplicate titles are currently not supported with this extension, ensure your entry titles are unique in the database."
        Write-Warning "Vault ${VaultName}: Filtered Non-Unique Titles: $($filteredRecords -join ', ')"
    }
    $sortedInfoResult
}