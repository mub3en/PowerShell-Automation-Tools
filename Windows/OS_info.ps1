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
    "\src\Functions\OS.ps1"
)

$moduleNames | ForEach-Object {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath $_
    Import-Module -Name $modulePath
}

# Get OS information
$os = Get-OperatingSystemInformation

# Display the hardware information in tabular form
DisplayTable "Operating System Information" $os

# Save the output to a text file
$outputPath = "${PSScriptRoot}\output\OS Info.txt"
$outputContent = @"
Operating System Information
----------------------

$($os | Out-String)
"@

Save-OutputToFile $outputPath $outputContent

Write-Host "Output saved to: $outputPath"