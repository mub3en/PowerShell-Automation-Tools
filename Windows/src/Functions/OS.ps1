function Get-OperatingSystemInformation {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $osName = $osInfo.Caption
    $osVersion = $osInfo.Version
    $osArchitecture = $osInfo.OSArchitecture
    $osSerialNumber = $osInfo.SerialNumber

    $operatingSystem = @{
        Name = $osName
        Version = $osVersion
        Architecture = $osArchitecture
        SerialNumber = $osSerialNumber
    }

    return $operatingSystem
}