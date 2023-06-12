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
    "\src\Functions\User-Group.ps1"
)

$moduleNames | ForEach-Object {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath $_
    Import-Module -Name $modulePath
}

# Get users and groups information
$u = Get-Users
$g = Get-Groups
DisplayTable "Users Information" $u
DisplayTable "Groups Information" $g


# Save the output to a text file
$outputPath = "${PSScriptRoot}\output\Users and Groups Info.txt"
$outputContent = @"
Users and Groups
----------------

Users information
$($u | Out-String)

Groups information
$($g | Out-String)
"@

Save-OutputToFile $outputPath $outputContent

Write-Host "Output saved to: $outputPath"