<#
By using the bitwise AND operator, we check if the bit corresponding to the 0x00000002 flag 
is set in the ProductState value. If the bit is set, it means that the antivirus is enabled. 
The expression ($antivirusStatus -band 0x00000002) will evaluate to a non-zero value if the antivirus is enabled.
#>
function Get-AntivirusStatus {
    $antivirusInfo = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiVirusProduct
    $antivirusStatus = $antivirusInfo | Select-Object -ExpandProperty ProductState
    $isAntivirusEnabled = ($antivirusStatus -band 0x00000002) -ne 0
    $isAntivirusUpToDate = ($antivirusStatus -band 0x00000080) -ne 0

    $antivirus = @{
        IsEnabled = $isAntivirusEnabled
        IsUpToDate = $isAntivirusUpToDate
    }

    return $antivirus
}

<#
The function can be written with WMI (Windows Management Instrumentation) 
instead of objectCIM (Common Information Model) Instance. 
#>
<#
function Get-AntivirusStatus {
    $antivirusInfo = Get-WmiObject -Namespace "Root\SecurityCenter2" -Class AntiVirusProduct
    $antivirusStatus = $antivirusInfo | Select-Object -ExpandProperty ProductState
    $isAntivirusEnabled = ($antivirusStatus -band 0x00000002) -ne 0
    $isAntivirusUpToDate = ($antivirusStatus -band 0x00000080) -ne 0

    $antivirus = @{
        IsEnabled = $isAntivirusEnabled
        IsUpToDate = $isAntivirusUpToDate
    }

    return $antivirus
}
#>

function Get-FirewallStatus {
    $firewallStatus = Get-NetFirewallProfile | Select-Object -Property Name, Enabled, LogMaxSizeKilobytes, LogFileName

    return $firewallStatus
}
