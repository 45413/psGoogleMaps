<#
.SYNOPSIS
    Utilize Google Maps API to geocode fuzzy address searches
.DESCRIPTION
    Give a query string and additional filters, Utilize Google Maps API to 
    identify valid address from ambigous text based addresses and return
    Longitutde, Latitude, and category for each address. 
    Showing multiple matches if found. 
.EXAMPLE
    PS> Get-Places -Search "jw marriott buckhead ga"

    query          : jw marriott buckhead ga
    matchedAddress : 3300 Lenox Rd NE, Atlanta, GA 30326, United States
    lat            : 33.84568409999999
    long           : -84.359663
    locationTypes  : {lodging, point_of_interest, establishment}
.EXAMPLE
    PS> Get-Places -Search "marriott buckhead ga" -LocationType lodging

    query          : marriott buckhead ga
    matchedAddress : 2220 Lake Blvd NE, Atlanta, GA 30319, United States
    lat            : 33.84902899999999
    long           : -84.34743499999999
    locationTypes  : {lodging, point_of_interest, establishment}

    query          : marriott buckhead ga
    matchedAddress : 3405 Lenox Rd NE, Atlanta, GA 30326, United States
    lat            : 33.84798300000001
    long           : -84.35995269999999
    locationTypes  : {lodging, restaurant, food, point_of_interest...}
    ...
#>
function Get-Places {
    [CmdletBinding()]
    param(
        # String to Search
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [string]
        $Search,
        # Lat,Long Array
        [Parameter(Mandatory=$false)]
        [Array]
        $LatLong,
        # Radius. Default is 25 miles
        [Parameter(Mandatory=$false)]
        [int]
        $Radius=25,
        # Location Type
        [Parameter(Mandatory=$false)]
        [Alias("Type")]
        [ValidateSet("accounting","airport","amusement_park","aquarium","art_gallery","atm","bakery","bank","bar","beauty_salon","bicycle_store","book_store","bowling_alley","bus_station","cafe","campground","car_dealer","car_rental","car_repair","car_wash","casino","cemetery","church","city_hall","clothing_store","convenience_store","courthouse","dentist","department_store","doctor","electrician","electronics_store","embassy","fire_station","florist","funeral_home","furniture_store","gas_station","gym","hair_care","hardware_store","hindu_temple","home_goods_store","hospital","insurance_agency","jewelry_store","laundry","lawyer","library","liquor_store","local_government_office","locksmith","lodging","meal_delivery","meal_takeaway","mosque","movie_rental","movie_theater","moving_company","museum","night_club","painter","park","parking","pet_store","pharmacy","physiotherapist","plumber","police","post_office","real_estate_agency","restaurant","roofing_contractor","rv_park","school","shoe_store","shopping_mall","spa","stadium","storage","store","subway_station","synagogue","taxi_stand","train_station","transit_station","travel_agency","university","veterinary_care","zoo")]
        [String]
        $LocationType
    )
    
    begin {
        $urlPrefix = "https://maps.googleapis.com/maps/api/place/textsearch/json"    
        $results = @()
    }
    
    process {
        #?location=-33.8670522,151.1957362&radius=500&type=restaurant&keyword=cruise&key=
        $parameters = "?query=$([uri]::EscapeDataString($Search))"

        # Added Latitude, Longitutde, and Radius filters  if provided        
        if ( $LatLong -is [array] -and $LatLong.Count -eq 2 ) {
            $parameters += "&location=$($latLong -join ',')&radius=$($Radius)"         
        }

        # Added LocationType if provided
        if ($LocationType) {
            $parameters += "&type=$($LocationType)"
        }

        if ($script:settings.apiKey) {
            $parameters += "&key=$($script:settings.apiKey)"         
        }            

        Write-Verbose "API Call: $($urlPrefix)$($parameters)"
        $response = Invoke-RestMethod -Uri "$($urlPrefix)$($parameters)" -Method Get -Verbose:$false      
        $results = @()
        
        switch ($response.status) {
            "OK" {
                # Main Logic
                if (($response.results | measure).Count -gt 1) {Write-Verbose "Multiple matches found for: $Search"}
                
                # Cycle through each result creating custom object and append to results array
                foreach ($line in $response.results) {
                    $results += [PSCustomObject] @{
                        "query"=$Search
                        "Name"=$line.name                    
                        "matchedAddress"=$line.formatted_address.toString()
                        "lat"=$line.geometry.location.lat
                        "long"=$line.geometry.location.lng
                        "locationTypes"=$line.types
                    }    
                }

                break
            }
            "ZERO_RESULTS" {
                Write-Verbose "no results found for $Search"
                $results += [PSCustomObject] @{
                    "query"=$Search
                    "Name"="No Match"
                    "matchedAddress"="No Match"
                    "lat"="No Match"
                    "long"="No Match"
                    "locationTypes"="No Match"
                }
            }
            "INVALID_REQUEST" {Write-Error "Invalid Request"; break}
            "REQUEST_DENIED" { Write-Error "Request Denied. This is most likely due to an invalid or missing API key."; break }
            "OVER_QUERY_LIMIT" { Write-Error "You have exceeded your API quota limit. Please try again."; break}
            Default {Write-Error "Unknown response status: `"$($respone.status)`""}
        }
        # if ($response.status -eq "OK") {
        #     if (($response.results | measure).Count -gt 1) {Write-Verbose "Multiple matches found for: $address"}

        #     foreach ($line in $response.results) {
        #         $results += [PSCustomObject] @{
        #             "fullAddress"=$line.formatted_address.toString();
        #             "lat"=$line.geometry.location.lat;
        #             "long"=$line.geometry.location.lng
        #         }    
        #     }
            
        # } elseif ($response.status -eq "ZERO_RESULTS") {
        #     $results += [PSCustomObject] @{
        #         "fullAddress"=$address;
        #         "lat"="No Match";
        #         "long"="No Match"
        #     }
        # } else {
        #     Write-Error "Recieved non-200 reponse code"
        # }
    }
    end {
        Write-Output $results
    }
}