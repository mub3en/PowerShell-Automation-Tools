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
    "\src\Functions\Output.ps1",
    "\src\Functions\Software-Installed.ps1"
)

$moduleNames | ForEach-Object {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath $_
    Import-Module -Name $modulePath
} 

#call Get-InstalledSoftware function
$output = Get-InstalledSoftware -DisplayFunction DisplayTable

# Display the output on the host
$output

# Save the output to a text file
$outputPath = "${PSScriptRoot}\output\Software Info.txt"
$outputContent = @"
List of installed softwares
----------------------

$output  
"@
Save-OutputToFile $outputPath $outputContent
Write-Host "Output saved to: $outputPath"