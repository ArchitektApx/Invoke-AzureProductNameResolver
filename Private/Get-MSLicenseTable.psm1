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
    $TableRows = $html.DocumentNode.SelectNodes('//table/tbody/tr')

    # used inside the foreach to warn only once on malformed results
    $AlreadyWarned = $false 
    
    $Output = foreach ($Row in $TableRows) {
        <#
            $RowCells[0] = Product Name
            $RowCells[1] = SKU/StringID
            $RowCells[2] = GUID
            $RowCells[3] = included service plans SKUs/StringIDs and GUIDs
            $RowCells[4] = included service plans productNames and GUIDs
        #>
        $RowCells = $Row.SelectNodes('td')

        # Filter out the last tds with non-compatible services that only list 2 properties (SKU and GUID)
        switch ($RowCells.count) {
            5 {
                # output the main product
                [AzureProduct]::new(
                    $RowCells[2].InnerHtml,
                    $RowCells[1].InnerHtml,
                    $RowCells[0].InnerHtml
                )

                if ($RowCells[3]) {
                    # create a Lookup Hashtable with each GUID:ProductName pair
                    $GuidToNameHt = @{}
                    foreach ($PlanName in $RowCells[4].SelectNodes('text()')) {
                        $ProdName, $GUID = ($PlanName.InnerText -split '\((?!.*\()')[0,1].Trim()
                        $GUID = $GUID.TrimEnd(')')
                        $GuidToNameHt[$GUID ] = $ProdName
                    }

                    foreach ($PlanSKU in $RowCells[3].SelectNodes('text()')) {
                        $SKU, $GUID = ($PlanSKU.InnerText -split '\((?!.*\()')[0,1].Trim()
                        $GUID = $GUID.TrimEnd(')')
                        # resolve the SKUs GUID to a productname, if no product name exists use the SKU as its Name
                        $Name = if ($null -ne $GuidToNameHt[$GUID]) { $GuidToNameHt[$GUID] } else { $SKU }

                        #output each included product
                        [AzureProduct]::New(
                            $GUID,
                            $SKU,
                            $Name
                        )
                    }
                }
            }
            2 { 

            }
            default {
                if ($AlreadyWarned -eq $false) {
                    Write-Warning 'Strange results were returned for microsoft table'
                    $AlreadyWarned = $true
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
