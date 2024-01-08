$PSModuleRoot = $PSScriptRoot

@(
    # Import class, public and private functions
    Get-ChildItem -Path $PSScriptRoot\private\*.ps1
    Get-ChildItem -Path $PSScriptRoot\public\*.ps1
).foreach{
    try { . $_.FullName } catch { throw $_ }
}

Read-Configuration

try {$host.UI.RawUI.WindowTitle="ConditionalAccessModular $version"} catch {}

$manifest = Import-PowerShellDataFile "$PSModuleRoot\ConditionalAccessModular.psd1"
$version = $manifest.ModuleVersion

$banner=@"
   ______                ___ __  _                   _____                            __  ___          __      __          
  / ____/___  ____  ____/ (_) /_(_)___  ____  ____ _/ /   | _____________  __________/  |/  /___  ____/ /_  __/ /___ ______
 / /   / __ \/ __ \/ __  / / __/ / __ \/ __ \/ __ ``/ / /| |/ ___/ ___/ _ \/ ___/ ___/ /|_/ / __ \/ __  / / / / / __ ``/ ___/
/ /___/ /_/ / / / / /_/ / / /_/ / /_/ / / / / /_/ / / ___ / /__/ /__/  __(__  |__  ) /  / / /_/ / /_/ / /_/ / / /_/ / /    
\____/\____/_/ /_/\__,_/_/\__/_/\____/_/ /_/\__,_/_/_/  |_\___/\___/\___/____/____/_/  /_/\____/\__,_/\__,_/_/\__,_/_/     

v$version by Kevin K. Kragh (@MrKragh)


"@

Write-Host $banner -ForegroundColor DarkCyan