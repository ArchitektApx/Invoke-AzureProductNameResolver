using module .\Classes\AzureProduct.psm1
using module .\Classes\AzureProductList.psm1
using module .\Classes\AzureProductResolver.psm1

Get-ChildItem "(Split-Path $script:MyInvocation.MyCommand.Path)Public*" -Filter '*.psm1' -Recurse | ForEach-Object { 
	. $_.FullName 
} 

Get-ChildItem "$(Split-Path $script:MyInvocation.MyCommand.Path)Public*" -Filter '*.psm1' -Recurse | ForEach-Object { 
	Export-ModuleMember -Function $_.Name 
}
