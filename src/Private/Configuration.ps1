function Read-Configuration {
    [cmdletbinding()]
    param()
    Process {
        # Clear the settings
        $Script:config = @{}

        # ConvertFrom-Json -AsHashtable not supported in PowerShell 5.1
        $configObject = Get-Content -Path "$PSModuleRoot\configuration.json" | ConvertFrom-Json
        foreach ($property in $configObject.PSObject.Properties) {
            $Script:config[$property.Name] = $property.Value
        }
    }
}