function Get-NetworkInformation {
    $networkAdapters = Get-NetAdapter

    $networkInfo = foreach ($adapter in $networkAdapters) {
        $ipv4Address = $adapter | Get-NetIPAddress -AddressFamily IPv4 |
            Select-Object -ExpandProperty IPAddress

        $ipv6Address = $adapter | Get-NetIPAddress -AddressFamily IPv6 |
            Select-Object -ExpandProperty IPAddress

        $dnsServers = $adapter | Get-DnsClientServerAddress |
            Select-Object -ExpandProperty ServerAddresses

        [PSCustomObject]@{
            InterfaceIndex = $adapter.InterfaceIndex
            Name = $adapter.Name
            Description = $adapter.Description
            IPv4Address = $ipv4Address
            IPv6Address = $ipv6Address
            DNSServers = $dnsServers
        }
    }

    return $networkInfo
}
