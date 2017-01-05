<#
.SYNOPSIS
    Retrieve psGoogleMaps Module Settings
.DESCRIPTION
    Retrieve user specific psGoogleMaps module settings. 
#>
function Get-psGoogleMapsSettings {
    [CmdletBinding()]
    param()

    if (test-path $script:moduleSettings) {
        # Import existing setting file
        Write-Verbose "Importing Settings from $($script:moduleSettings)."
        
        $tmp = Get-Content -Path $script:moduleSettings -Raw | ConvertFrom-Json
        return $tmp  
    } else {
        Write-Verbose "No settings file found."
       return $false
    }
}

<#
.SYNOPSIS
    Write out psGoogleMaps Module Settings
.DESCRIPTION
    Store user specific psGoogleMaps module settings. 
#>
function Set-psGoogleMapsSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        $InputObject
    )
        
    #Check if settings exist already. if not create file.
    if (-not (test-path $script:moduleSettings)) {
        New-Item -ItemType File -Path $script:moduleSettings -Force
    }
    $InputObject | ConvertTo-Json | Out-File $script:moduleSettings
    
}