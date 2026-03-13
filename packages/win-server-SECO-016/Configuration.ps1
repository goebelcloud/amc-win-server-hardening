<#
File: Configuration.ps1
Package: win-server-SECO-016 - Accounts: Rename guest account
Purpose: Renames the built-in Guest account (RID 501) to a non-default name (parameterized via GuestNewName).
Version: 1.0.0
#>

# win-server-SECO-016: Accounts: Rename guest account
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Accounts: Rename guest account = Rename to non-default (even if disabled)
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_016_Accounts_Rename_guest_account {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {

        # Parameter file used for Machine Configuration parameter overrides.
        # The File resource property "Contents" can be overridden via Azure Policy / Machine Configuration parameters.
        File SECO_016_ParameterFolder {
            DestinationPath = "C:\ProgramData\MachineConfiguration\win-server-SECO-016"
            Type            = "Directory"
            Ensure          = "Present"
        }

        File SECO_016_GuestNameParameter {
            DestinationPath = "C:\ProgramData\MachineConfiguration\win-server-SECO-016\GuestNewName.txt"
            Type            = "File"
            Ensure          = "Present"
            Contents        = "LocalGuest"  # Default; can be overridden using configuration parameters
            DependsOn       = "[File]SECO_016_ParameterFolder"
        }

        Script SECO_016 {
            DependsOn = "[File]SECO_016_GuestNameParameter"

            GetScript  = {
                $parameterFilePath = "C:\ProgramData\MachineConfiguration\win-server-SECO-016\GuestNewName.txt"
                $desiredName = (Get-Content -Path $parameterFilePath -ErrorAction SilentlyContinue | Select-Object -First 1)
                if ($null -ne $desiredName) { $desiredName = $desiredName.Trim() }
                if ([string]::IsNullOrWhiteSpace($desiredName)) { $desiredName = "LocalGuest" }

                $user = Get-LocalUser | Where-Object { $_.SID.Value -match "-501`$" } | Select-Object -First 1
                $currentName = if ($user) { $user.Name } else { "" }

                return @{
                    Result = "CurrentName=$currentName;DesiredName=$desiredName"
                }
            }

            TestScript = {
                $parameterFilePath = "C:\ProgramData\MachineConfiguration\win-server-SECO-016\GuestNewName.txt"
                $desiredName = (Get-Content -Path $parameterFilePath -ErrorAction SilentlyContinue | Select-Object -First 1)
                if ($null -ne $desiredName) { $desiredName = $desiredName.Trim() }
                if ([string]::IsNullOrWhiteSpace($desiredName)) { $desiredName = "LocalGuest" }

                $user = Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID.Value -match "-501`$" } | Select-Object -First 1
                if (-not $user) { return $false }

                return ($user.Name -eq $desiredName)
            }

            SetScript  = {
                $parameterFilePath = "C:\ProgramData\MachineConfiguration\win-server-SECO-016\GuestNewName.txt"
                $desiredName = (Get-Content -Path $parameterFilePath -ErrorAction SilentlyContinue | Select-Object -First 1)
                if ($null -ne $desiredName) { $desiredName = $desiredName.Trim() }
                if ([string]::IsNullOrWhiteSpace($desiredName)) { $desiredName = "LocalGuest" }

                $user = Get-LocalUser | Where-Object { $_.SID.Value -match "-501`$" } | Select-Object -First 1
                if (-not $user) { throw "Unable to find built-in Guest account (RID 501)." }

                if ($user.Name -ne $desiredName) {
                    try {
                        Rename-LocalUser -Name $user.Name -NewName $desiredName
                    }
                    catch {
                        throw "Failed to rename built-in Guest account from '$($user.Name)' to '$desiredName'. Error: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}
