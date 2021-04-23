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
    $SKUTable = $html.DocumentNode.SelectNodes("//div[@class='wp-block-syntaxhighlighter-code ' and contains(., 'skuids = @{')]").FirstChild.InnerText

    $StringContent = $SKUTable -replace "\`$skuids = @{|}|'", '' -split ';'
    foreach ($line in $StringContent) {
        $Split = $line.Split('=').Trim()
        $ExtendedLookup[$($Split[0])] = $Split[1]
    }

    return $ExtendedLookup
}
