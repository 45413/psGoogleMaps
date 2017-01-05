<#
.SYNOPSIS
    Utilize Google Maps API to Geocode street address
.DESCRIPTION
    Give one or more addresses, Utilize Google Maps API to validate and return
    Longitutde and Latitude for each address. Showing multiple matches if found. 
.EXAMPLE
    Get-Geocoding -Address "1 Microsoft Way"

    fullAddress                                    lat         long
    -----------                                    ---         ----
    1 Microsoft Way, Redmond, WA 98052, USA 47.6393225 -122.1283833

.EXAMPLE
    Get-Geocoding -Address "1 Microsoft Way","1600 Amphitheatre Parkway"

    fullAddress                                                 lat         long
    -----------                                                 ---         ----
    1 Microsoft Way, Redmond, WA 98052, USA              47.6393225 -122.1283833
    1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA 37.4223582 -122.0844464
#>
function Get-Geocoding {
    [CmdletBinding()]
    param(
        # Address to geocode
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [string[]]
        $Addresses,
        # Google Maps API key
        [Parameter(Mandatory=$false)]
        [string]
        $ApiKey
    )
    
    begin {
        $urlPrefix = "https://maps.googleapis.com/maps/api/geocode/json"    
        $results = @()
    }
    
    process {
        foreach ($address in $Addresses) {
            $parameters = "?address=$([uri]::EscapeDataString($address))"

            if ($script:settings.apiKey) {
                $parameters += "&key=$($script:settings.apiKey)"         
            }            
    
            $response = Invoke-RestMethod -Uri "$($urlPrefix)$($parameters)" -Method Get -Verbose:$false       
            $results = @()

            switch ($response.status) {
                "OK" {
                    # Main Logic
                    if (($response.results | measure).Count -gt 1) {Write-Verbose "Multiple matches found for: $Search"}
                    
                    # Cycle through each result creating custom object and append to results array
                    foreach ($line in $response.results) {
                        $results += [PSCustomObject] @{
                            "fullAddress"=$line.formatted_address.toString();
                            "lat"=$line.geometry.location.lat;
                            "long"=$line.geometry.location.lng;
                        }    
                    }

                    break
                }
                "ZERO_RESULTS" {
                    Write-Verbose "no results found for $Search"
                    $results += [PSCustomObject] @{
                        "fullAddress"=$address;
                        "lat"="No Match";
                        "long"="No Match";
                    }
                }
                "INVALID_REQUEST" {Write-Error "Invalid Request"; break}
                "REQUEST_DENIED" { Write-Error "Request Denied. This is most likely due to an invalid or missing API key."; break }
                "OVER_QUERY_LIMIT" { Write-Error "You have exceeded your API quota limit. Please try again."; break}
                Default {Write-Error "Unknown response status: `"$($respone.status)`""}
            }
        }
    }
    end {
        Write-Output $results
    }
}