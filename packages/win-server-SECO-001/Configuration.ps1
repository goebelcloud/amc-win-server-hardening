<#
File: Configuration.ps1
Package: win-server-SECO-001 - Accounts Limit local account use of blank passwords to conso
Purpose: Enforces a Windows security hardening registry setting: Accounts Limit local account use of blank passwords to conso.
Version: 1.0.0
#>

Configuration SECO_001_Accounts_Limit_local_account_use_of_blank_passwords {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "LimitBlankPasswordUse"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
