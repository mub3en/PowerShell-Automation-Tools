function Get-InstalledSoftware {
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Get-Command $_ -ErrorAction SilentlyContinue})]
        [string]$DisplayFunction,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFilePath
    )

    $software = Get-WmiObject -Class Win32_Product
    $output = & $DisplayFunction "Installed Software" $software

    return $output
}
