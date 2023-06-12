@echo off
setlocal

REM Get the current directory of the batch script
set "scriptFolder=%~dp0"

REM Change to the script folder
cd /d "%scriptFolder%"

REM Array of script filenames to execute
set "scripts=AV_Firewall_status.ps1 OS_info.ps1 Server_Hardware_info.ps1 software_info.ps1 server_network_info.ps1 users_groups_info.ps1"

REM Execute each PowerShell script
for %%i in (%scripts%) do (
    echo Executing %%i
    powershell.exe -ExecutionPolicy Bypass -File "%%i"
)

endlocal
