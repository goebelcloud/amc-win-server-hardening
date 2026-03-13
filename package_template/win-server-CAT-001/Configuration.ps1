Configuration Sample_WinServer_CAT_001 {
  Import-DscResource -ModuleName PSDscResources

  Node localhost {
    Registry SampleTemplateSetting {
      Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso\MachineConfigurationTemplate'
      ValueName = 'Enabled'
      ValueType = 'Dword'
      ValueData = 1
      Ensure    = 'Present'
      Force     = $true
    }
  }
}
