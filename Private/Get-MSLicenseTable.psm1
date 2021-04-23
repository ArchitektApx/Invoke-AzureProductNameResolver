function Get-MSLicenseTable {
    [OutputType([AzureProductList])]
    [CmdletBinding()]
    param (
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # fetch Microsoft table
    $WebRequestParams = @{
        Uri             = 'https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference'
        UseBasicParsing = $true
    }
    try {
        $Response = Invoke-WebRequest @WebRequestParams 
    } catch {
        throw $_
    }

    $html = [HtmlAgilityPack.HtmlDocument]::new()
    $html.LoadHtml($Response.content)
    $TableRows = $html.DocumentNode.SelectNodes('//table//tbody//tr').InnerHTML
    
    $Output = foreach ($Row in $TableRows) {
        <#
            $RowCells[0] = Product Name
            $RowCells[1] = SKU/StringID
            $RowCells[2] = GUID
            $RowCells[3] = included service plans SKUs/StringIDs and GUIDs
            $RowCells[4] = included service plans productNames and GUIDs
        #>
        $RowCells = ($Row | Select-String -Pattern '<td>(.*?)</td>' -AllMatches).Matches | ForEach-Object { $_.Groups[1].Value }

        # Filter out the last tables with non-compatible services that only liste 2 properties (SKU and GUID)
        if ($RowCells.count -gt 2) {

            # output the main product
            [AzureProduct]::new(
                $RowCells[2],
                $RowCells[1],
                $RowCells[0]
            )

            if ($RowCells[3]) {
                # create a Lookup Hashtable with each GUID:ProductName pair
                $GuidToNameHt = @{}
                foreach ($Plan in ($RowCells[4] -Split '<br>')) {
                    $Split = ($Plan -split '\((?!.*\()').Trim(')').Trim()
                    $GuidToNameHt[$Split[1]] = $Split[0]
                }

                foreach ($SKU in ($RowCells[3] -Split '<br>')) {
                    $Split = ($SKU -split '\((?!.*\()').Trim(')').Trim()
                    # resolve the SKUs GUID to a productname, if no product name exists use the SKU as its Name
                    $Name = if ($null -ne $GuidToNameHt[$Split[1]]) { $GuidToNameHt[$Split[1]] } else { $Split[0] }

                    #output each included product
                    [AzureProduct]::New(
                        $Split[1],
                        $Split[0],
                        $Name
                    )
                }
            }
        }
    }

    $MicrosoftLookup = [AzureProductList]::New()
    foreach ($azureproduct in ($Output | Sort-Object -Property GUID -Unique)) {
        [void]$MicrosoftLookup.Add($azureproduct)
    } 

    # https://stackoverflow.com/a/17498737
    return , $MicrosoftLookup
}
