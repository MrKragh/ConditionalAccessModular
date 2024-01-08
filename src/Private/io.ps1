

function Format-Filename {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$name
    )
    process {
        return $name.Split([System.IO.Path]::GetInvalidFileNameChars()) -join '' -replace " ", "_"
    }
}

function Get-FiletypeExtension {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]]$Filetype
    )
    process {
        if ($filetypes[$Filetype]) {
            return $filetypes[$Filetype]
        }
        else {
            Write-Warning "Unknown file type: $Filetype"
            return "txt"
        }         
    }
}

function Get-ObjectType {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]]$Type
    )
    begin {
        $lookup = @{
            "NamedLocations" = @(
                "countryNamedLocation"
                "ipNamedLocation"
            )
        }
    }
    process {
        foreach ($key in $lookup.Keys) {
            if ($Type -in $lookup[$key]) {
                return $key
            }
        }
        Write-Warning "Unknown object type: $Type"
        return "Unknown"
    }
}

function Get-DataLocation {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [String]$Type
    )
    process {
        $workdir = Get-ConfigurationItem -Item "Workdir"
        if ($type) {
            return [IO.Path]::Combine($workdir, $Type)
        }
        else {
            return $workdir
        } 
    }

}

function Confirm-OutputLocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$Type
    )
    process {
        $fullpath = Get-DataLocation -Type $Type

        if (-not (Test-Path $fullpath -PathType Container)) {
            New-Item -ItemType Directory -Path $fullpath -Force | Out-Null
        }
        
        return $fullpath
    }
}

function Get-FileFormat {
    [CmdletBinding()]
    param()
    process {
        return Get-ConfigurationItem -Item "FileFormat"
    }
}

function Convert-ObjectTo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]$InputObject,
        [String]$FileFormat
    )
    process {
        switch ($FileFormat) {
            "json" {
                $InputObject | ConvertTo-Json -Depth 10
            }
            "yaml" {
                $InputObject | ConvertTo-Yaml
            }
            Default {
                Write-Warning "Unknown format: $FileFormat"
            }
        }
    }
}

function Convert-ObjectFrom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]$InputObject,
        [String]$Format
    )
    process {
        $result = switch ($format) {
            "json" {
                $InputObject | ConvertFrom-Json
            }
            "yaml" {
                $InputObject | ConvertFrom-Yaml
            }
            Default {
                Write-Warning "Unknown format: $format"
                $InputObject
            }
        }
        return $result
    }
}

function Get-InputIbjects {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [String]$Type
    )
    process {
        # If no inpuit object is provided, we identify the input files.
        $InputPath = Get-DataLocation -Type $Type
        $InputFormat = Get-FileFormat
        $InputExtension = Get-FiletypeExtension -Filetype:$InputFormat

        if (-not(Test-Path -Path $InputPath -PathType Container)) {
            Write-Error "Input path does not exist: $InputPath" -ErrorAction Stop
        }

        $InputFiles = [IO.Path]::Combine($InputPath, "*.$InputExtension") | Get-ChildItem
        if (-not($InputFiles)) {
            Write-Error "No files found in $InputPath with extension $InputExtension" -ErrorAction Stop
        }
        return Get-ChildItem $InputFiles | Get-Content -Raw | Convert-ObjectFrom -Format $InputFormat 
    }
}

function ConvertTo-Element {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]$InputObject,
        [Parameter(Mandatory)]
        [String]$Type
    )
    Process {
        return "$Type($InputObject)"
    }
}

function ConvertFrom-Element {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$InputObject
    )
    Process {
        $result = $InputObject -match "(?<Type>\w+)\((?<Data>.*)\)"
        if ($result) {
            Write-Debug "Match successful. Type: $($Matches['Type']), Data: $($Matches['Data'])"
            $value = switch ($Matches['Type']) {
                "Country" { Get-CountryCode -Country $Matches['Data'] }
                Default {
                    Write-Warning "Unknown element type: $($Matches['Type'])"
                }
            }
            
        } else {
            Write-Debug "Match not successful for $InputObject."
            $value = $InputObject
        }
        return $value
    }

}