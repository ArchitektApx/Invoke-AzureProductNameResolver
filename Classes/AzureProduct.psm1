class AzureProduct {
    [GUID]$GUID
    [string]$SKU
    [string]$Name

    AzureProduct ([GUID]$GUID, [string]$SKU, [string]$Name) {
        $this.GUID = $GUID
        $this.SKU = $SKU
        $this.Name = $Name
    }

    AzureProduct ([string]$SKU, [string]$Name) {
        $this.SKU = $SKU
        $this.Name = $Name
    }
}