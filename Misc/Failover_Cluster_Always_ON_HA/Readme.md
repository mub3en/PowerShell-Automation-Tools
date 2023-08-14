# Steps to create a Failover Cluster with Always ON High Availability.

1. Install VMWare ✅
2. Download SQL Sever and Cumulative Package ✅
3. Download Windows OS Images ✅

 ``If above mentioned steps are complete, start by creating:`` 

4. Add a VM host that would be the Domain Controller (DC) ✅
5. One Primary Server and Required Number of Replicas ✅
    * Memory 2 Gigs and Storage 60 gigs for DC ✅
    * Memory 4 Gigs and Storage 100 gigs for ✅
  
``OR``

6. Create Primary Server and Install SQL Server
7. [Clone](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation?view=windows-11) Primary to make number of desired replicas. 

``Once VMWare and OS are installed``

8. Install VMWare tools ✅
9. Update VMWare Network Adapter to Bridge if it’s not. Usually its on NAT. ✅
10. Update Windows Network Adapter and change it to Static from DHCP ✅
    * ``Set IPv4 address: for example: 192.168.1.50 given default gateway starts with 192.168.1.*``✅
        * Keep adding 1 in each server and point the default DNS to DC. For example: 
            * ``IPv4 address: 192.168.1.51``
            * ``IPv4 DNS Server: 192.168.1.50``
    * ``Set IPv4 Subnet Mask: 255.255.255.0``
    * ``Set IPv4 Default gateway: 192.168.1.1 (from your ISP)``
    * ``Set IPv4 DNS Server: 192.168.1.1 (from your ISP)``
    * ``Set secondary IPv4 DNS Server: 192.168.1.1 (from your ISP - Optional)``
<details>
<Summary>PowerShell code to update static IP:</Summary>

```PowerShell:
#get identity of the current user and verify if its an administrator 
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$TestAdmin = (New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if ($TestAdmin -eq $false) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($MyInvocation.MyCommand.Definition))
    exit $LASTEXITCODE
}

# Define the parameters
$interfaceName = "Ethernet0"  # Change this to the name of your network interface
$ipAddress = "192.168.1.200"  # Change this to the desired IP address
$subnetMask = "255.255.255.0"  # Change this to the desired subnet mask
$defaultGateway = "192.168.1.1"  # Change this to the desired default gateway
$preferredDNS = "192.168.1.1"  # Change this to the preferred DNS server
$alternateDNS = "127.0.0.1
"  # Change this to the alternate DNS server (optional)

# Get the network interface
$networkInterface = Get-NetAdapter | Where-Object { $_.Name -eq $interfaceName }

if ($networkInterface -eq $null) {
    Write-Host "Network interface '$interfaceName' not found."
    exit
}

# Set the IP address settings
New-NetIPAddress -InterfaceIndex $networkInterface.InterfaceIndex -IPAddress $ipAddress -PrefixLength 24 -DefaultGateway $defaultGateway

# Set the DNS server settings
$dnsSettings = @{
    InterfaceIndex = $networkInterface.InterfaceIndex
    ServerAddresses = @($preferredDNS)
}
if ($alternateDNS) {
    $dnsSettings.ServerAddresses += $alternateDNS
}
Set-DnsClientServerAddress @dnsSettings

Write-Host "TCP/IPv4 settings changed successfully."
```
</details>
11. Change Computer Name ✅
12. Share Network Drive ✅
13. Install Domain Controller Service on DC ✅
14. Repeat Step 8 - 12 on all servers. ✅
15. Split partition into 3 drives: ✅
    - SQL DATA 40 Gigs (D)
        - ``If letter D is already used by Shared Drive or DVD ROM, change the assigned letter first. Go to cmd:``
                     
           ```
           > DiskPart
           > List Volume
           > SELECT VOLUME <ASSIGNED NUMBER to D>
           > assign letter=D
           ```
           
    - TempDB 10 Gigs (T)
    - Log 10 Gigs (L)
<details>
<Summary>Powershell code to rename/create partitions:"</Summary>
 
 ```
 $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$TestAdmin = (New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if ($TestAdmin -eq $false) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($MyInvocation.MyCommand.Definition))
    exit $LASTEXITCODE
}

# Specify the percentage sizes for each partition
$percentageC = 40
$percentageD = 40
$percentageL = 10
$percentageT = 10

# Specify the drive letter of the existing partition
$existingDriveLetter = "C"

# Get the existing partition details
$existingPartition = Get-Partition -DriveLetter $existingDriveLetter

if ($existingPartition -eq $null) {
    Write-Host "Existing partition not found."
    exit
}


# Get used drive letters for partitions and drives (excluding OS drive)
$usedDriveLetters = (Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $existingDriveLetter }).DriveLetter
$usedDriveLetters += (Get-WmiObject Win32_CDROMDrive).Drive


# Check if drive letter "D" is used
if ($usedDriveLetters -like "D*") {
    # Check if drive letter "Z" is available
    # if ($usedDriveLetters -contains "Z") {
    #     Write-Host "Drive letter Z is already in use. Please free up the drive letter Z manually."
    #     exit
    # }
    
    # Get the CD/DVD-ROM drives
    $cdDrives = Get-WmiObject Win32_CDROMDrive
    
    # Check if any CD/DVD-ROM drives are assigned drive letter "D"
    $cdWithD = $cdDrives | Where-Object { $_.Drive -like "D*" }
        if ($cdWithD) {
        # Get the current drive letter and device ID of the CD/DVD-ROM drive
        $currentDrive = $cdWithD.Drive
        # $deviceID = $cdWithD.DeviceID

        # Change the drive letter of the CD/DVD-ROM drive using DiskPart
        $diskPartScript = @"
        select volume $currentDrive
        assign letter=Z
"@
        $diskPartScript | DiskPart
        $usedDriveLetters = $usedDriveLetters -replace "D", "Z"
    }
    else {
        Write-Host "Drive letter D is used, but no CD/DVD-ROM drives are assigned that letter."
    }
}

# Calculate the sizes in bytes based on percentages
$totalSizeBytes = $existingPartition.Size - 5300000
$sizeCBytes = [math]::Floor($totalSizeBytes * ($percentageC / 100))
$sizeDBytes = [math]::Floor($totalSizeBytes * ($percentageD / 100))
$sizeLBytes = [math]::Floor($totalSizeBytes * ($percentageL / 100))

# Calculate available space for the last partition
$usedSpaceBytes = $sizeCBytes + $sizeDBytes + $sizeLBytes
$availableSpaceBytes = $totalSizeBytes - $usedSpaceBytes
$sizeTBytes = $availableSpaceBytes

# Resize the existing partition to the desired size for C: (OS)
Resize-Partition -DiskNumber $existingPartition.DiskNumber -PartitionNumber $existingPartition.PartitionNumber -Size $sizeCBytes

# Specify the new drive letters and sizes for the partitions along with their desired names
$partitions = @(
    @{ DriveLetter = "D"; Size = $sizeDBytes; Name = "DATA" },
    @{ DriveLetter = "L"; Size = $sizeLBytes; Name = "LOGS" },
    @{ DriveLetter = "T"; Size = $sizeTBytes; Name = "TempDB" }
)

$existingVolumes = Get-Partition
$maxPartitionNumber = ($existingVolumes | Measure-Object -Property PartitionNumber -Maximum).Maximum

foreach ($partition in $partitions) {
    $maxPartitionNumber++
    
    # Create the partition
    $partitionSize = $partition.Size
    $driveLetter = $partition.DriveLetter
    $partitionNumber = $maxPartitionNumber

    New-Partition -DiskNumber $existingPartition.DiskNumber -Size $partitionSize
    $volume = Get-Partition -DiskNumber $existingPartition.DiskNumber -PartitionNumber $partitionNumber

    # Format the partition with the desired drive letter
    Format-Volume -Partition $volume -FileSystem NTFS -Confirm:$false -Force
    $volume | Set-Partition -NewDriveLetter $driveLetter

    # Rename the drive with the desired name
    Set-Volume -DriveLetter $driveLetter -NewFileSystemLabel $partition.Name

    Write-Host "Partition with drive letter $($partition.DriveLetter) created successfully and renamed to $($partition.Name)."
}

Write-Host "Partitions created successfully."
 ```
</details>

16. Create SQLAdmin, SSIS, SSRS users in AZ directory ✅


``Install SQL Server(s):``

17. Launch downloader and SELECT a NEW Instance install ✅
18. Make sure to point DATA, LOG and TEMPDB to their respective drive ✅
19. Make sure to add users we created in Active Directory for SQL ✅

``After SQL Server Install Complete:``

20. Add Firewall rules to allow 1433 for TCP and 1434 for UDP on each server ✅
21. Add Firewall rules to allow 5022 for TCP on each server ✅
22. Enable TCP/IP from SQL Server Configure Manager ✅
23. Install Failover Cluster feature on each server ✅
24. Enable Always On Availability Group from SQL Server Configuration Manager ✅

25. Restore Database(s) and Set RECOVERY to FULL ✅
26. Take a Full backup on a shared location ✅
27. A SQL Login should have sysadmin access and should be a windows administrator ✅

``Failover Test``

28. Test failing a server and see if it responds in an expected manner ✅
29. Primary replica if not configured as “Readable”, on Failover  when it becomes a secondary, it won’t be readable ✅

``Setting up Maintenance Plan``

30. Setup a maint task ✅
    * Typical maintenance tasks
        * ``Check Database integrity``
            * [DBCC CHECKDB](https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-checkdb-transact-sql?view=sql-server-ver16)
            * [How to Automate the SQL Server DBCC CheckDB](https://www.sqlshack.com/automate-the-sql-server-dbcc-checkdb-command-using-maintenance-plans/)
        * ``Reorganize and/or Rebuild Indexes``
            * [Optimize Index maintenance](https://learn.microsoft.com/en-us/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-ver16)
            * [Maintaining SQL Server indexes](https://www.sqlshack.com/maintaining-sql-server-indexes/)
            * [Identify and resolve SQL Server Index Fragmentation](https://www.sqlshack.com/how-to-identify-and-resolve-sql-server-index-fragmentation/)
        * ``Update Statistics ( cannot be done on read only replica)``
            * [UPDATE STATISTICS](https://learn.microsoft.com/en-us/sql/t-sql/statements/update-statistics-transact-sql?view=sql-server-ver16)
            * [SQL Server Statistics](https://www.sqlshack.com/sql-server-statistics-and-how-to-perform-update-statistics-in-sql/)
        * ``Backup Database (Full/Log)  (Differential backup cannot be performed on the read-only database)``
            * [BACKUP (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql?view=sql-server-ver16)
            * [Create a Full Database Backup](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-full-database-backup-sql-server?view=sql-server-ver16)
            * [Create a Differential Database Backup](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-differential-database-backup-sql-server?view=sql-server-ver16)
            * [Backup a Transaction Log](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/back-up-a-transaction-log-sql-server?view=sql-server-ver16)
            * [SQL Server Backup, Integrity Check, and Index and Statistics Maintenance](https://ola.hallengren.com/)
        * ``Cleanup History from msdb if needed``
            * [MSDB SQL Database Maintenance and Cleanup](https://www.sqlshack.com/msdb-sql-database-maintenance-and-cleanup/)
            * [Clear Backup History](https://sqlsolutionsgroup.com/how-to-clear-backup-history/) 
        * ``Shrink Database (It is recommended that you never execute this action as part of any regular maintenance as it leads to severe index fragmentation which can harm database performance.)``
            * [Shrink a database](https://learn.microsoft.com/en-us/sql/relational-databases/databases/shrink-a-database?view=sql-server-ver16)
            * [Shrink the tempdb database](https://learn.microsoft.com/en-us/sql/relational-databases/databases/shrink-tempdb-database?view=sql-server-ver16)   
        * Shrink Database Log
            * [DBCC SHRINKFILE (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-shrinkfile-transact-sql?view=sql-server-ver16)
            * [How to shrink the transaction log](https://www.mssqltips.com/sqlservertutorial/3311/how-to-shrink-the-transaction-log/)  




# Ref Article
1 - [SQL hack -  SQL Server Always On Availability Groups](https://www.sqlshack.com/a-comprehensive-guide-to-sql-server-always-on-availability-groups-on-windows-server-2016/)
