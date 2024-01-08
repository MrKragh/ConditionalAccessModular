function Get-NamedLocations { 
    # TODO: Add docstring
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.signins/get-mgidentityconditionalaccessnamedlocation
    [CmdletBinding()]
    param(
        [switch]$Beta
    )
    $command = Get-GraphCommand "Get-MgIdentityConditionalAccessNamedLocation" -Beta:$Beta

    return Invoke-GraphCommand $command
}

function Update-NamedLocation {
    # TODO: Add docstring
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.signins/update-mgidentityconditionalaccessnamedlocation
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]$InputObject,
        [switch]$Beta,
        [Switch]$Force
    )

    $Arguments = @{
        "NamedLocationId" = $InputObject.Id 
        "BodyParameter"   = $InputObject.Params
    }

    $command = Get-GraphCommand "Update-MgIdentityConditionalAccessNamedLocation" -Beta:$Beta
    Invoke-GraphCommand $command $Arguments
    exit
    return 
}

function ConvertTo-NamedLocation {
    # https://learn.microsoft.com/en-us/graph/api/resources/namedlocation
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphNamedLocation[]]$InputObject,
        [switch]$Transform
    )
    process {
        Write-Verbose "Formatting Conditional Access Named Location : $($InputObject.DisplayName)"
        Write-Debug "Conditional Access Named Location : $($InputObject | ConvertTo-Json -Depth 10)"

        $result = [PSCustomObject]@{
            Id   = $InputObject.Id
            Type = ($InputObject.AdditionalProperties."@odata.type" -split "\." | Select-Object -Last 1)
            Name = $InputObject.DisplayName
        }

        switch ($result.Type) {

            "CountryNamedLocation" {
                $result | Add-Member -MemberType NoteProperty -Name "CountryLookupMethod" -Value $InputObject.AdditionalProperties.countryLookupMethod 
                $result | Add-Member -MemberType NoteProperty -Name "IncludeUnknownCountriesAndRegions" -Value $InputObject.AdditionalProperties.includeUnknownCountriesAndRegions
                $result | Add-Member -MemberType NoteProperty -Name "CountriesAndRegions" -Value $InputObject.AdditionalProperties.countriesAndRegions
                if($Transform){
                    $result.CountriesAndRegions = $result.CountriesAndRegions | Get-CountryName | ConvertTo-Element -Type "Country" 
                }
            }

            "IpNamedLocation" {
                $result | Add-Member -MemberType NoteProperty -Name "IsTrusted" -Value $InputObject.AdditionalProperties.isTrusted 
                $result | Add-Member -MemberType NoteProperty -Name "IpRanges" -Value $InputObject.AdditionalProperties.ipRanges.cidrAddress
            }

            Default {
                Write-Warning "Unknown Named Location Type: $($result.Type)"
            }
        }
        
        return $result
    }
}

function ConvertFrom-NamedLocation {
    # https://learn.microsoft.com/en-us/graph/api/resources/namedlocation
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]$InputObject
    )
    process {
        Write-Verbose "Formatting Conditional Access Named Location : $($InputObject.Name)"
        Write-Debug "Conditional Access Named Location : $($InputObject | ConvertTo-Json -Depth 10)"

        $result = [PSCustomObject]@{
            Id     = $InputObject.Id
            Params = @{
                "@odata.type" = "#microsoft.graph.$($InputObject.Type)"
                displayName   = $InputObject.Name
            }
        }

        switch ($InputObject.Type) {

            "CountryNamedLocation" {
                $result.Params["countryLookupMethod"] = $InputObject.CountryLookupMethod
                $result.PArams["includeUnknownCountriesAndRegions"] = $InputObject.IncludeUnknownCountriesAndRegions
                $result.Params["countriesAndRegions"] = $InputObject.CountriesAndRegions | ConvertFrom-Element

                if ($null -eq $InputObject.CountriesAndRegions) {
                    $result.Params["countriesAndRegions"] = @()
                }
                elseif ($InputObject.CountriesAndRegions -is [String]) {
                    $result.Params["countriesAndRegions"] = @($result.Params["countriesAndRegions"])
                }
            }

            "IpNamedLocation" {
                $result | Add-Member -MemberType NoteProperty -Name "IsTrusted" -Value $InputObject.AdditionalProperties.isTrusted 
                $result | Add-Member -MemberType NoteProperty -Name "IpRanges" -Value $InputObject.AdditionalProperties.ipRanges.cidrAddress
            }

            Default {
                Write-Warning "Unknown Named Location Type: $($result.Type)"
            }
        }
        
        return $result
    }
}

function Export-NamedLocations {
    # TODO: Add docstring
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]$InputObject,
        [Switch]$Transform,
        [String]$FileFormat,
        [switch]$Force
    )
    process {
        $InputObject | ConvertTo-NamedLocation -Transform:$Transform | Out-Format -FileFormat:$FileFormat -Force:$Force
    }
}

function Import-NamedLocations {
    # TODO: Add docstring
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [Object[]]$InputObject,
        [switch]$Force
    )
    process {
        if ($InputObject) {
            Write-Verbose ($InputObject | ConvertTo-Json -Depth 10)
            $InputObject | ConvertFrom-NamedLocation | Update-NamedLocation -Force:$Force
        }
        else {
            # If no input object is provided, we read the input files and give to self.
            Get-InputIbjects -Type "NamedLocations" | Import-NamedLocations -Force:$Force
        }
    }
}

function Get-CountryCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$Country

    )
    process {
        $CountryCode = $CountryCodes.GetEnumerator()| Where-Object { $_.Value -eq $Country } | Select-Object -ExpandProperty Key
        if ($null -eq $CountryCode) {
            Write-Warning "Unknown country: $Country"
        } else {
            return $CountryCode
        }
    }
}

function Get-CountryName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$Country

    )
    process {
        $CountryCode = $CountryCodes[$Country]
        if ($null -eq $CountryCode) {
            Write-Warning "Unknown country: $Country"
        } else {
            return $CountryCode
        }
    }
}