class AzureProductList : System.Collections.ArrayList {

    AzureProductList() {}

    [bool] Contains ($SearchString) {
        foreach ($value in ($this.SKU,$this.Name,$this.GUID)) {
            if ($value -eq $SearchString) { return $true }
        }
        return $false
    }
}