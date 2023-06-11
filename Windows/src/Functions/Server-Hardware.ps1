function Get-SystemInformation {
    $systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    $manufacturer = $systemInfo.Manufacturer
    $model = $systemInfo.Model
    $serialNumber = $systemInfo.SerialNumber
    $systemType = $systemInfo.SystemType
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $osVersion = $osInfo.Version

    Get-CimInstance -Class Win32_OperatingSystem 

    $system = @{
        Manufacturer = $manufacturer
        Model = $model
        SerialNumber = $serialNumber
        SystemType = $systemType
        OSVersion = $osVersion
    }

    # return $system.GetEnumerator() | ForEach-Object {
    #     $_.Value
    # }

    return $system
}

function Get-ProcessorInformation {
    $processorInfo = Get-CimInstance -ClassName Win32_Processor
    $processorName = $processorInfo.Name
    $numberOfCores = $processorInfo.NumberOfCores
    $numberOfLogicalProcessors = $processorInfo.NumberOfLogicalProcessors

    $processor = @{
        Name = $processorName
        NumberOfCores = $numberOfCores
        NumberOfLogicalProcessors = $numberOfLogicalProcessors
    }

    return $processor
}

function Get-MemoryInformation {
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory
    $memoryCapacity = ($memoryInfo.Capacity | Measure-Object -Sum).Sum / 1GB
    $memorySlots = $memoryInfo.Count

    $memory = @{
        Capacity = $memoryCapacity
        Slots = $memorySlots
    }

    return $memory
}

function Get-DiskInformation {
    $diskInfo = Get-CimInstance -ClassName Win32_DiskDrive
    $diskCapacity = ($diskInfo.Size | Measure-Object -Sum).Sum / 1TB
    $diskModel = $diskInfo.Model
    $diskInterfaceType = $diskInfo.InterfaceType

    $disk = @{
        Capacity = $diskCapacity
        Model = $diskModel
        InterfaceType = $diskInterfaceType
    }

    return $disk
}

function Get-NetworkAdapterInformation {
    $networkAdapterInfo = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
    $networkAdapterName = $networkAdapterInfo.Name
    $networkAdapterMACAddress = $networkAdapterInfo.MACAddress

    $networkAdapter = @{
        Name = $networkAdapterName
        MACAddress = $networkAdapterMACAddress
    }

    return $networkAdapter
}

