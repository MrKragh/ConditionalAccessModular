function Get-GraphCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $Command,
        [switch] $Beta
    )
    begin {
        $beta = Get-ConfigurationItem -Item "Beta"
        $lookup = @{
            "Get-MgIdentityConditionalAccessNamedLocation"    = "Get-MgBetaIdentityConditionalAccessNamedLocation"
            "Update-MgIdentityConditionalAccessNamedLocation" = "Update-MgBetaIdentityConditionalAccessNamedLocation"
        }
    }
    process {
        if ($lookup.ContainsKey($Command)) {
            if ($beta) {
                $Command = $lookup[$Command]
            }
            return $Command
        }
        else {
            Write-Error "Unable to lookup Graph command: $Command"
        }
    }
}

function Invoke-GraphCommand {
    # TODO: Add docstring
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [String] $Command,
        [Parameter(Position = 1)]
        [Hashtable] $ArgumentList
    )
    process {
        $method = Get-ConfigurationItem -Item "DefaultConnectionMethod"
        switch ($method) {
            "Token" {
                $null = Connect-UsingToken
            }
            "Custom" {}
            default {
                Write-Warning "Unknown connection method: $method"
            }
        }
        if ($ArgumentList) {
            Write-Verbose "Calling: $Command, with arguments: $($ArgumentList | ConvertTo-Json -Compress)"
            return & $Command @ArgumentList
        }
        else {
            Write-Verbose "Calling: $Command"
            return & $Command
        }       
    }
}