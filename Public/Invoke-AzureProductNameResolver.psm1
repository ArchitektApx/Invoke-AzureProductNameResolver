using module .\..\Classes\AzureProductResolver.psm1

<#
.SYNOPSIS
    An OS agonostic powershell module for translation of Azure SKUs,GUIDs and Product Names (= Friendly Names) with each other.
.DESCRIPTION
    Provides an object of class AzureProductResolver which crawls the official 
    azure license table[1] and a more extensive SKU/ProductName collection made by
    Phillip Föckler[2]. Once fetched and parsed (or loaded from a savefile) the object provides fast and easy
    methods to translate each type into every other.

    Works on Powershell 5 and Powershell Core with every OS supported by these.

    Microsoft has no available method of translating GUIDS/SKUs to 
    ProductNames/FriendlyNames - but this will do it :) 

    [1] https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference
    [2] https://scripting.up-in-the.cloud/licensing/list-of-o365-license-skuids-and-names.html
.PARAMETER Lookupmode
    LookupMode decides which lists will be searched 
    1: microsoft only (Supports GUID/SKUs/ProductNames)
    2: extended only (Supports SKUs/ProductNames)
    3: microsoft first, if not found extended (Supports SKUs/ProductNames) 
    4: extended first, if not found microsoft (Supports SKUs/ProductNames)
.PARAMETER FilePath
    A Filepath that represents a savefile that was saved via the .SaveConfig('path\to\file')
.EXAMPLE
    # Invoke the Resolver
    $Resolver = Invoke-AzureProductNameResolver
.EXAMPLE
    # Invoke from Savefile
    $Resolver = Invoke-AzureProductNameResolver -FilePath 'path\to\file'
.EXAMPLE
    # Resolve GUIDS/SKUs to a FriendlyName / ProductName
    $Resolver.ResolveGUIDtoName("$GUID")
    $Resolver.ResolveSKUtoName("$SKU")
.EXAMPLE
    # Resolve all else
    $Resolver.ResolveNametoSKU("$Name")
    $Resolver.ResolveNametoGUID("$Name")
    $Resolver.ResolveSKUtoGUID("$SKU")
    $Resolver.ResolveGUIDtoSKU("$GUID")

.EXAMPLE
    # Save the fetched and parsed data for later use
    $Resolve.SaveConfig('path\to\file')
.EXAMPLE
    # Change the lookup mode without creating a new object
    $Resolve.ChangeLookupMode([int]$Lookupmode)
.NOTES
    A big thank you to Phlllip Föckler for not only collecting his very extensive list
    which is way more detailed than the one provided by Microsoft but also for 
    heavily inspiring the making of thiswith his awesome awesome blogpost on this topic. 
    https://scripting.up-in-the.cloud/about
    https://scripting.up-in-the.cloud/licensing/o365-license-names-its-a-mess.html 

    HTML Parsing is made with HtmlAgilityPack which is an awesome OS agnostic Nuget Package.
    https://html-agility-pack.net/

    Author:
    https://github.com/ArchitektApx
    https://github.com/MohnJcAfee

    License:
    MIT
.OUTPUTS 
    [AzureProductResolver]
#>

function Invoke-AzureProductNameResolver {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]
        $LookupMode,
        [Parameter(Mandatory = $false)]
        [string]
        $FilePath
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    if ($FilePath) {
        [AzureProductResolver]::New("$FilePath")
    } elseif ($LookupMode) {
        [AzureProductResolver]::New($LookupMode)
    } else {
        [AzureProductResolver]::New()
    }
}
