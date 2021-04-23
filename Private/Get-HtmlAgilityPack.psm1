function Get-HtmlAgilityPack {
    [CmdletBinding()]
    param (
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # check if nuget is available
    try {
        $GetParams = @{
            ListAvailable = $true
            Name          = 'Nuget'
            ErrorAction   = 'Stop'
        }

        Get-PackageProvider @GetParams
    } catch {
        try {
            $InstallParams = @{
                Name           = 'Nuget'
                Scope          = 'CurrentUser'
                Force          = $true
                MinimumVersion = '2.8.5.201'
                ErrorAction    = 'Stop'
            }

            Install-PackageProvider @InstallParams | Out-Null
        } catch {
            throw $_
        }
    }


    # Check if HtmlAgilityPack is installed and import the dll
    try {
        $GetParams = @{
            Name        = 'HtmlAgilityPack'
            ErrorAction = 'Stop'
        }

        Get-Package @GetParams | Out-Null
    } catch {
        try {
            $InstallParams = @{
                Name             = 'HtmlAgilityPack'
                Source           = 'https://www.nuget.org/api/v2'
                Scope            = 'CurrentUser'
                SkipDependencies = $true
                Force            = $true
                ErrorAction      = 'Stop'
            }

            Install-Package @InstallParams | Out-Null
        } catch {
            throw $_
        }
    } finally {
        $dlls = Get-ChildItem -Recurse -Filter *.dll -LiteralPath (Join-Path (Split-Path (Get-Package HtmlAgilityPack).Source) lib/netstandard2.0)

        if (-not ($null -eq $dlls)) {
            $dlls | ForEach-Object { 
                try {
                    $TypeParams = @{
                        LiteralPath = $_.FullName 
                        ErrorAction = 'Stop' 
                    }
                    Add-Type @TypeParams
                } catch {
                    throw $_
                }
            }
        } else {
            throw [System.IO.FileNotFoundException]::New('lib/netstandard2.0/HtmlAgilityPack.dll not found')
        }
    }
}
