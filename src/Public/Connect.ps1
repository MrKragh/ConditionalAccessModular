function Connect-UsingToken {
    # TODO: Add docstring
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $params
    )

    # Get the current context
    $AzContext = Get-AzContext
    $MgContext = Get-MgContext

    if($null -eq $MgToken -or $MgToken.ExpiresOn -lt (Get-Date)){
        $refresh = $true
    }

    # If we're not connected, or the token is expired, connect
    if($null -eq $AzContext -or $refresh) {     
        if ($null -eq $params) { Connect-AzAccount -SkipContextPopulation} else { Connect-AzAccount @params }
        $global:MgToken = Get-AzAccessToken -ResourceTypeName MSGraph  # TODO: While debugging this is global, but should be scoped to the module
    }

    # If we're not connected to graph, connect
    if($null -eq $MgContext -or $refresh) {
        Connect-MgGraph -NoWelcome -AccessToken ($MgToken.Token | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction Stop
    }
}

function Disconnect-Token {
    Remove-Variable MgToken
    Disconnect-MgGraph
    Disconnect-AzAccount
}