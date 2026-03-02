<#
File: Configuration.ps1
Package: win-server-LSA-001 - Enable LSA protection RunAsPPL
Purpose: Enforces a Windows security hardening registry setting: Enable LSA protection RunAsPPL.
Version: 1.0.0
#>

Configuration LSA_001_Enable_LSA_protection_RunAsPPL {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-LSA-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "RunAsPPL"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
