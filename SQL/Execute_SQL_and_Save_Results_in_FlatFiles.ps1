enum ExitCodes {
    DatabaseConnectivityTestFailed = 1
    DatabaseLoginFailed = 2
    DatabaseConnectionFailed = 3
    DatabaseUnknownException = 4
    DatabaseSettigsNotDefined = 5
    LaunchedNonElevated = 6
    DatabaseNameNotFound = 7
    UnknownException = 8
}

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

#Import PowerShell Libraries
$moduleNames = @(
    "\src\Modules\sqlserver.21.1.18256\SqlServer.psd1",
    "\src\Modules\requirements.2.3.6\Requirements.psd1"
)

$moduleNames | ForEach-Object {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath $_
    Import-Module -Name $modulePath
}
#Import Custom Modules/Functions
Import-Module -Name "${PSScriptRoot}\src\Functions\Functions.ps1"

#Call SQL Server Information function. 
$serverInfo = Get-SqlServerInfo

try{
    Get-ChildItem "${PSScriptRoot}\src\Scripts\" -Filter *.sql |
    ForEach-Object{
        #$_ wil get FileInfo inside Script\ directory
        $ScriptPath = "${PSScriptRoot}\src\Scripts\$_"
        #$_.ToString() will get the file name with extension '.sql'. To give a readable name lets trim 'Get' & '.sql' from the file name.
        #for example: 'GetStudents.sql' => 'Students.csv'
        $creatingCSVFile = $_.ToString().Substring(3, $_.ToString().Substring(0,$_.ToString().indexof(".")).length - 3)
        $outputPath = "{0}\output\CSV_Files\{1}.csv" -f ${PSScriptRoot}, $creatingCSVFile

        if(Test-Path -Path $ScriptPath){
            Write-Host "Executing Script $_ "
            $scriptOutPut = Invoke-Sqlcmd -ServerInstance $serverInfo.SQLServerInstance -Database $serverInfo.SQLDatabaseName -Credential $serverInfo.SQLLogin -InputFile $ScriptPath
            
            if(Test-Path -Path $outputPath){
                Write-Host "$creatingCSVFile.csv file already exists."
            }else{
                Write-Host "Saving results in $creatingCSVFile.csv."
                $scriptOutPut | Export-Csv $outputPath -Delimiter ',' -NoTypeInformation
            }
        }

    }
}
catch [System.Data.SqlClient.SqlException]{
    $ErrorDetails = Format-Error -Exception $_ -Depth 2

    switch -Wildcard ($ErrorDetails.Exception.Message){
        '*The server was not found or was not accesible.*'{
            Write-Error "Connection to the database server failed." -ErrorAction Continue
            exit [ExitCodes]::DatabaseConnectionFailed
        }
        'Login failed for user*'{
            Write-Error "Login to the database server failed." -ErrorAction Continue
            exit [ExitCodes]::DatabaseLoginFailed
        }
        'Cannot open database*requested by the login. The login failed.*'{
            Write-Error ($ErrorDetails.Exception.Message -split '\r\n')[0] -ErrorAction Continue
            exit [ExitCodes]::DatabaseNameNotFound
        }
        Default {
            Write-Error "An unexpected database error occured."
            exit [ExitCodes]::DatabaseUnknownException
        }
    }
}
catch {
    $ErrorDetails = Format-Error -Exception $_
    write-host $ErrorDetails.Exception.Message
    Write-Error "An unexpected error occured" -ErrorAction Continue
    exit [ExitCodes]::UnknownException

}
finally{
    if($ErrorDetails){
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $errorOutputPath = "${PSScriptRoot}\errors\StackTrace_$timestamp.txt"
        $ErrorDetails | Out-File $errorOutputPath 
    }
}