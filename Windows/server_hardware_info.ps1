#get identity of the current user and verify if its an administrator 
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$TestAdmin = (New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if($TestAdmin -eq  $false){
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($MyInvocation.MyCommand.Definition))
    exit $LASTEXITCODE
}

#Set Literal Path from the location it gets executed.
Set-Location -LiteralPath $PSScriptRoot
Push-Location $PSScriptRoot

#Import Custom Modules/Functions
$moduleNames = @(
    "\src\Functions\Display.ps1",
    "\src\Functions\Output.ps1",
    "\src\Functions\Server-Hardware.ps1"
)

$moduleNames | ForEach-Object {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath $_
    Import-Module -Name $modulePath
}

# Get PC hardware information
$system = Get-SystemInformation
$processor = Get-ProcessorInformation
$memory = Get-MemoryInformation
$disk = Get-DiskInformation
$networkAdapter = Get-NetworkAdapterInformation

# Display the hardware information in tabular form
DisplayTable "System Information" $system
DisplayTable "Processor Information" $processor
DisplayTable "Memory Information" $memory
DisplayTable "Disk Information" $disk
DisplayTable "Network Adapter Information" $networkAdapter

# Save the output to a text file
$outputPath = "${PSScriptRoot}\output\Server Hardware Information.txt"
$outputContent = @"
PC Hardware Information
----------------------

System Information
$($system | Out-String)

Processor Information
$($processor | Out-String)

Memory Information
$($memory | Out-String)

Disk Information
$($disk | Out-String)

Network Adapter Information
$($networkAdapter | Out-String)
"@

Save-OutputToFile $outputPath $outputContent

Write-Host "Output saved to: $outputPath"
