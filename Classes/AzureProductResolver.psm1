using module .\AzureProduct.psm1
using module .\AzureProductList.psm1
using module .\..\Private\Get-HtmlAgilityPack.psm1
using module .\..\Private\Get-ExtendedLicenseTable.psm1
using module .\..\Private\Get-MSLicenseTable.psm1

class AzureProductResolver {
    hidden [AzureProductList] $MSLicenseTable
    hidden [hashtable] $ExtendedLicenseTable
    hidden [int] $LookupMode
    
    AzureProductResolver () {
        $this.LookupMode = 1
        $this.Init()
    }

    AzureProductResolver ([int]$LookupMode) {
        $this.LookupMode = $LookupMode
        $this.Init()
    }

    AzureProductResolver ([string]$FilePath) {
        if ( Test-Path -Path "$FilePath" -PathType Leaf ) {
            try {
                $SavedFile = Import-Clixml -Path "$FilePath" -ErrorAction Stop
                $this.LookupMode = $SavedFile.LookupMode
                $this.ExtendedLicenseTable = $SavedFile.ExtendedLicenseTable
                $this.MSLicenseTable = [AzureProductList]::New()
                $SavedFile.MSLicenseTable | ForEach-Object { [void]$this.MSLicenseTable.Add($_) }
            } catch {
                throw $_
            }
        } else {
            throw [System.IO.FileNotFoundException]::new("File $FilePath was not found")  
        }

        $this.LoadHtmlAgilityPack()
    }

    hidden [void] Init() {
        # Force TLS 1.2 in older powershell versions
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $this.LoadHtmlAgilityPack()
        $this.MSLicenseTable = Get-MSLicenseTable
        $this.ExtendedLicenseTable = Get-ExtendedLicenseTable
    }

    hidden [void] LoadHtmlAgilityPack () {
        Get-HtmlAgilityPack
    }

    hidden [void] CheckGUIDUnsupported () {
        if ($this.LookupMode % 2 -eq 0 ) {
            throw [System.InvalidOperationException]::New('GUID translation is not supported with use with the extended lookup table')
        }
    }

    hidden [string] ResolveMSLicenseTable ($source, [string]$informat, [string]$outformat) {
        foreach ($Product in $this.MSLicenseTable) {
            if ($Product."$informat" -eq $source) { return $Product."$outformat" }
        }
        return $null
    }

    hidden [string] ResolveExtendedLicenseTable ([string]$source, [string]$informat) {
        switch ($informat) {
            SKU {
                return $this.ExtendedLicenseTable["$($source)"]
            }
            Name {
                foreach ($License in $this.ExtendedLicenseTable.GetEnumerator()) {
                    if ($source -eq $License.Value) { return $License.Key }
                }
            }
        }
        return $null
    }

    hidden [string] ResolveLookupModeSwitch ($value, $informat, $outformat) {
        switch ($this.LookupMode) {
            1 {
                return $this.ResolveMSLicenseTable($value, $informat, $outformat)
            }
            2 {
                return $this.ResolveExtendedLicenseTable($value, $informat)
            }
            3 {
                $result = $this.ResolveMSLicenseTable($value, $informat, $outformat)
                if ($null -eq $result) {
                    $result = $this.ResolveExtendedLicenseTable($value, $informat)
                }
                return $result
            }
            4 {
                $result = $this.ResolveExtendedLicenseTable($value, $informat) 
                if ($null -eq $result) {
                    $result = $this.ResolveMSLicenseTable($value, $informat, $outformat)
                }
                return $result
            }
        }
        return $null
    }

    [string] ResolveGUIDtoSKU([guid]$GUID) {
        $this.CheckGUIDUnsupported()
        if ($this.MSLicenseTable.Contains($GUID)) {
            return $this.ResolveMSLicenseTable($GUID, 'GUID', 'SKU')
        }
        return $null
    }

    [string] ResolveGUIDtoName ([guid]$GUID) {
        $this.CheckGUIDUnsupported()
        if ($this.MSLicenseTable.Contains($GUID)) {
            return $this.ResolveMSLicenseTable($GUID, 'GUID', 'Name')
        }
        return $null
    }

    [string] ResolveSKUtoGUID ([string]$SKU) {
        $this.CheckGUIDUnsupported()
        if ($this.MSLicenseTable.Contains($SKU)) {
            return $this.ResolveMSLicenseTable($SKU, 'SKU', 'GUID')
        }
        return $null
    }

    [string] ResolveNameToGUID ([string]$Name) {
        $this.CheckGUIDUnsupported()
        if ($this.MSLicenseTable.Contains($Name)) {
            return $this.ResolveMSLicenseTable($Name, 'Name', 'GUID')
        }
        return $null
    }

    [string] ResolveSKUtoName ($SKU) {
        return $this.ResolveLookupModeSwitch($SKU, 'SKU', 'Name')
    }

    [string] ResolveNameToSKU ($Name) {
        return $this.ResolveLookupModeSwitch($Name, 'Name', 'SKU')
    }

    [void] ChangeLookupMode ([int]$LookupMode) {
        $this.LookupMode = $LookupMode
    }
    
    [void] SaveConfig ([string]$FilePath) {
        try {
            $this | Export-Clixml -Path "$FilePath"
        } catch {
            throw $_
        }
    }
}