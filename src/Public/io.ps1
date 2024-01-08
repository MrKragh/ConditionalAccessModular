function Out-Format {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $InputObject,
        $FileFormat,
        [switch]$Force
    )
    begin {
        if(-not $FileFormat) {
            $FileFormat = Get-FileFormat
        }
        $extension = Get-FiletypeExtension -Filetype:$FileFormat
    }
    process {
        # Have to do this every time as objects can change type
        $ObjectType = $InputObject.Type | Get-ObjectType
        $path = Confirm-OutputLocation -Type $ObjectType

        $filename = $InputObject.Name | Format-Filename
        $file = [IO.Path]::Combine($path, "$filename.$extension")

        if ((Test-Path $file -PathType Leaf -ErrorAction SilentlyContinue) -and (-not $Force)) {
            Write-Warning "File $file already exists. Use -Force to overwrite."
            return
        }
        else {
            $InputObject | Convert-ObjectTo -FileFormat $FileFormat | Out-File -FilePath $file -Force
        }
    }
}

