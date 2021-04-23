# Invoke-AzureProductNameResolver

An OS agonostic powershell module for translation of Azure SKUs,GUIDs and Product Names (= Friendly Names) with each other.

## The Module 
The Module provides an object of class AzureProductResolver that crawls the official [Azure license table](https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference) and a more extensive [SKU/ProductName collection](https://scripting.up-in-the.cloud/licensing/list-of-o365-license-skuids-and-names.html) made by Phillip Föckler. 
Once fetched and parsed (or loaded from a savefile) the object provides fast and easy methods to translate each type into every other.

Works on **Powershell 5, Powershell Core** and with every OS supported by these.

Microsoft has no available method of translating GUIDS/SKUs to ProductNames/FriendlyNames in a program/script - **but this will do it :)** 

## Lookupmode
The LookupMode decides which of the fetched lists will be searched:
   - 1: Microsoft only (Supports GUID/SKUs/ProductNames)
   - 2: Extended only (Supports SKUs/ProductNames)
   - 3: Microsoft first, if not found Extended (Supports SKUs/ProductNames) 
   - 4: Extended first, if not found Microsoft (Supports SKUs/ProductNames)

1 is set as default to ensure GUID compatability but translating SKUs and Product Names the extended list is heavily prefered since it is way more extensive (+900 records) vs the microsoft list which only has around 300 products listed.

## Example Usage 
```powershell
    # Invoke the Resolver
    $Resolver = Invoke-AzureProductNameResolver

    # Create a savefile
    $Resolve.SaveConfig('path\to\file')
    
    # Invoke the Resolver from a previous savefile
    $Resolver = Invoke-AzureProductNameResolver -FilePath '\path\to\file'

    # Public methods should be pretty self explaining
    $Resolver.ResolveGUIDtoName("$GUID")
    $Resolver.ResolveSKUtoName("$SKU")
    $Resolver.ResolveNametoSKU("$Name")
    $Resolver.ResolveNametoGUID("$Name")
    $Resolver.ResolveSKUtoGUID("$SKU")
    $Resolver.ResolveGUIDtoSKU("$GUID")

    # Change the lookup mode without creating a new object
    $Resolve.ChangeLookupMode([int]$Lookupmode)
```

## Notes and mentions 

A big thank you to [Phlllip Föckler](https://scripting.up-in-the.cloud/about) for not only collecting his very extensive list which is way more detailed than the one provided by Microsoft but also for 
heavily inspiring the making of this with his awesome [blogpost](https://scripting.up-in-the.cloud/licensing/o365-license-names-its-a-mess.html ) on this topic. 

HTML Parsing is made with [HtmlAgilityPack (HAP)](https://html-agility-pack.net/) which is an awesome OS agnostic Nuget Package.