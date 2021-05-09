function Get-ExtendedLicenseTable {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $ExtendedLookup = @{}

    # fetch Phillips extended table
    $WebRequestParams = @{
        Uri             = 'https://scripting.up-in-the.cloud/licensing/list-of-o365-license-skuids-and-names.html'
        UseBasicParsing = $true
    }
    try {
        $Response = Invoke-WebRequest @WebRequestParams 
    } catch {
        throw $_
    } 

    $html = [HtmlAgilityPack.HtmlDocument]::new()
    $html.LoadHtml($Response.content)
    $SKUTable = $html.DocumentNode.SelectNodes("//pre[contains(., 'skuids = @{')]").InnerText

    $StringContent = $SKUTable.Trim().TrimStart('$skuids = @{').TrimEnd('}').Split([System.Environment]::NewLine).TrimEnd(';').Trim() | . { process {
            # can't filter with a better regex since Microsoft doesn't always adhere to their standard SKU format 
            if ($_ -match "^'.*'='.*'$" ) { $_ }
            elseif ( $_ -eq '') {}
            else { Write-Warning -Message 'Strange results were returned for extended table' }
        } }

    foreach ($line in $StringContent) {
        $SKU, $Name = $line.Split('=')[0, 1].Trim().Trim("'")
        $ExtendedLookup[$SKU] = $Name
    }

    return $ExtendedLookup
}
