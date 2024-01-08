

function Save-Configuration {
    [cmdletbinding()]
    param()
    Process {
        $file = "$PSModuleRoot\configuration.json"
        $Script:config | ConvertTo-Json | Set-Content -Path $file

        Write-Output "Configuration saved to $file"
    }
}

function Get-Configuration {
    [cmdletbinding()]
    param()
    Process {
        $Script:config
    }
}

function Get-ConfigurationItem {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [string]$Item
    )
    Process {
        return $Script:config[$Item]
    }
}

function Set-ConfigurationItem {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Item,
        [parameter(Mandatory, ValueFromPipeline, Position = 1)]
        [PSObject]$Value
    )
    Process {
        $Script:config[$Item] = $value
    }
}