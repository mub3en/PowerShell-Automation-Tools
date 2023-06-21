#get identity of the current user and verify if its an administrator 
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$TestAdmin = (New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if ($TestAdmin -eq $false) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($MyInvocation.MyCommand.Definition))
    exit $LASTEXITCODE
}

#Set Literal Path from the location it gets executed.
Set-Location -LiteralPath $PSScriptRoot
Push-Location $PSScriptRoot

#Import PowerShell libraries & custom modules/functions
$modules = @(
    "\src\Modules\sqlserver.21.1.18256\SqlServer.psd1"
    # ,"\src\Modules\requirements.2.3.6\Requirements.psd1"
    , "\src\Functions\ExitCodes.ps1"
    , "\src\Functions\Functions.ps1"
    , "\src\Functions\Get-SQLFunctions.ps1"
    , "\src\Functions\GUI-Components.ps1"
)

$modules | ForEach-Object {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath $_
    Import-Module -Name $modulePath
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

#Call SQL Server authentication function 
# $serverInfo = Get-SqlServerInfo

try {
    Write-Host "Execution starts here..." 
    $SQLServerName = Read-Host 'Input the SQL Server name without instance '
    $SQLInstance = Read-Host 'Input the SQL Instance name, if any - Hit enter if empty '
    
    $SQLServerInstance = if ([string]::IsNullOrEmpty($SQLInstance)) {
        $SQLServerName  
    } else {
        "{0}\{1}" -f $SQLServerName, $SQLInstance
    }
    

    # if([string]::IsNullOrEmpty($SQLServerInstance)){return}

    #calling Get-CustomSqlAgent function
    $CSVPath = "{0}\output\CSV_Files\SQL_Agent_Info.csv" -f ${PSScriptRoot}
    $TextPath = "{0}\output\Text_Files\SQL_Agent_Info.txt" -f ${PSScriptRoot}
    $HTMLPath = "{0}\output\HTML_Files\SQL_Agent_Info.html" -f ${PSScriptRoot}
    $CustomFuncHolder = Get-CustomSqlAgent -ServerInstance $SQLServerInstance
    Write-host "SQL agent information is being written to a CSV, text and a HTML file.."
    $CustomFuncHolder | Export-Csv -Path $CSVPath -NoTypeInformation
    $CustomFuncHolder | Out-File -FilePath $TextPath -Encoding UTF8
    $CustomFuncHolder = Import-Csv -Path $CSVPath
    Save-CSVtoHtmlTable  -ReportLabel "SQL server '${SQLServerInstance}' agent information" -CsvObject $CustomFuncHolder -OutputFilePath $HTMLPath 
    
    #calling Get-CustomSqlAgentJob function
    $CSVPath = "{0}\output\CSV_Files\SQL_Agent_Job_Info.csv" -f ${PSScriptRoot}
    $TextPath = "{0}\output\Text_Files\SQL_Agent_Job_Info.txt" -f ${PSScriptRoot}
    $HTMLPath = "{0}\output\HTML_Files\SQL_Agent_Job_Info.html" -f ${PSScriptRoot}
    $CustomFuncHolder = Get-CustomSqlAgentJob -ServerInstance $SQLServerInstance
    Write-host "SQL agent job information is being written to a CSV, text and a HTML file.."
    $CustomFuncHolder | Export-Csv -Path $CSVPath -NoTypeInformation
    $CustomFuncHolder | Out-File -FilePath $TextPath -Encoding UTF8
    $CustomFuncHolder = Import-Csv -Path $CSVPath
    Save-CSVtoHtmlTable  -ReportLabel "SQL server '${SQLServerInstance}' jobs information" -CsvObject $CustomFuncHolder -OutputFilePath $HTMLPath
    
    #calling Get-CustomSqlAgentJobHistory function
    $CSVPath = "{0}\output\CSV_Files\SQL_Agent_Job_History.csv" -f ${PSScriptRoot}
    $TextPath = "{0}\output\Text_Files\SQL_Agent_Job_History.txt" -f ${PSScriptRoot}
    $HTMLPath = "{0}\output\HTML_Files\SQL_Agent_Job_History.html" -f ${PSScriptRoot}
    $CustomFuncHolder = Get-CustomSqlAgentJobHistory -ServerInstance $SQLServerInstance
    Write-host "SQL agent job history is being written to a CSV, text and a HTML file.."
    $CustomFuncHolder | Export-Csv -Path $CSVPath -NoTypeInformation
    $CustomFuncHolder | Out-File -FilePath $TextPath -Encoding UTF8
    $CustomFuncHolder = Import-Csv -Path $CSVPath
    Save-CSVtoHtmlTable  -ReportLabel "SQL Server '${SQLServerInstance}' jobs history" -CsvObject $CustomFuncHolder -OutputFilePath $HTMLPath

    #calling Get-CustomSqlAgentJobSchedule function
    $CSVPath = "{0}\output\CSV_Files\SQL_Agent_Job_Schedule.csv" -f ${PSScriptRoot}
    $TextPath = "{0}\output\Text_Files\SQL_Agent_Job_Schedule.txt" -f ${PSScriptRoot}
    $HTMLPath = "{0}\output\HTML_Files\SQL_Agent_Job_Schedule.html" -f ${PSScriptRoot}
    $CustomFuncHolder = Get-CustomSqlAgentJobSchedule -ServerInstance $SQLServerInstance
    Write-host "SQL agent job schedule is being written to a CSV, text and a HTML file.."
    $CustomFuncHolder | Export-Csv -Path $CSVPath -NoTypeInformation
    $CustomFuncHolder | Out-File -FilePath $TextPath -Encoding UTF8
    $CustomFuncHolder = Import-Csv -Path $CSVPath
    Save-CSVtoHtmlTable  -ReportLabel "SQL Server '${SQLServerInstance}' jobs schedule" -CsvObject $CustomFuncHolder -OutputFilePath $HTMLPath


    #calling Get-CustomSqlAgentJobSteps function
    $CSVPath = "{0}\output\CSV_Files\SQL_Agent_Job_Steps.csv" -f ${PSScriptRoot}
    $TextPath = "{0}\output\Text_Files\SQL_Agent_Job_Steps.txt" -f ${PSScriptRoot}
    $HTMLPath = "{0}\output\HTML_Files\SQL_Agent_Job_Steps.html" -f ${PSScriptRoot}
    $CustomFuncHolder = Get-CustomSqlAgentJobSteps -ServerInstance $SQLServerInstance
    Write-host "SQL agent job schedule is being written to a CSV, text and a HTML file.."
    $CustomFuncHolder | Export-Csv -Path $CSVPath -NoTypeInformation
    $CustomFuncHolder | Out-File -FilePath $TextPath -Encoding UTF8
    $CustomFuncHolder = Import-Csv -Path $CSVPath
    Save-CSVtoHtmlTable  -ReportLabel "SQL Server '${SQLServerInstance}' jobs steps" -CsvObject $CustomFuncHolder -OutputFilePath $HTMLPath
   

    #calling Get-CustomSqlAgentSchedule function
    $CSVPath = "{0}\output\CSV_Files\SQL_Agent_Schedule.csv" -f ${PSScriptRoot}
    $TextPath = "{0}\output\Text_Files\SQL_Agent_Schedule.txt" -f ${PSScriptRoot}
    $HTMLPath = "{0}\output\HTML_Files\SQL_Agent_Schedule.html" -f ${PSScriptRoot}
    $CustomFuncHolder = Get-CustomSqlAgentSchedule -ServerInstance $SQLServerInstance
    Write-host "SQL agent schedule is being written to a CSV, text and a HTML file.."
    $CustomFuncHolder | Export-Csv -Path $CSVPath -NoTypeInformation
    $CustomFuncHolder | Out-File -FilePath $TextPath -Encoding UTF8
    $CustomFuncHolder = Import-Csv -Path $CSVPath
    Save-CSVtoHtmlTable  -ReportLabel "SQL Server '${SQLServerInstance}' agent schedule." -CsvObject $CustomFuncHolder -OutputFilePath $HTMLPath
   
    #calling Get-CustomSqlAssessmentItem function
    $CSVPath = "{0}\output\CSV_Files\SQL_Server_Objects_Assessment_List.csv" -f ${PSScriptRoot}
    $TextPath = "{0}\output\Text_Files\SQL_Server_Objects_Assessment_List.txt" -f ${PSScriptRoot}
    $HTMLPath = "{0}\output\HTML_Files\SQL_Server_Objects_Assessment_List.html" -f ${PSScriptRoot}
    #calling with all properties -DefaultProperties $false
    $CustomFuncHolder = Get-CustomSqlAssessmentItem -ServerInstance $SQLServerInstance -DefaultProperties $false
    Write-host "SQL server assessment for the objects is being written to a CSV, text and a HTML file.."
    $CustomFuncHolder | Export-Csv -Path $CSVPath -NoTypeInformation
    $CustomFuncHolder | Out-File -FilePath $TextPath -Encoding UTF8
    $CustomFuncHolder = Import-Csv -Path $CSVPath
    Save-CSVtoHtmlTable  -ReportLabel "SQL Server '${SQLServerInstance}' Assessment List." -CsvObject $CustomFuncHolder -OutputFilePath $HTMLPath


    #calling Get-CustomSqlBackupHistory function
    $CSVPath = "{0}\output\CSV_Files\SQL_Backup_history.csv" -f ${PSScriptRoot}
    $TextPath = "{0}\output\Text_Files\SQL_Backup_history.txt" -f ${PSScriptRoot}
    $HTMLPath = "{0}\output\HTML_Files\SQL_Backup_history.html" -f ${PSScriptRoot}
    #calling with all properties -DefaultProperties $false
    $CustomFuncHolder = Get-CustomSqlBackupHistory -ServerInstance $SQLServerInstance -DefaultProperties $false
    Write-host "SQL server backup history is being written to a CSV, text and a HTML file.."
    $CustomFuncHolder | Export-Csv -Path $CSVPath -NoTypeInformation
    $CustomFuncHolder | Out-File -FilePath $TextPath -Encoding UTF8
    $CustomFuncHolder = Import-Csv -Path $CSVPath
    Save-CSVtoHtmlTable  -ReportLabel "SQL Server '${SQLServerInstance}' Backup History." -CsvObject $CustomFuncHolder -OutputFilePath $HTMLPath
 
}
catch [System.Data.SqlClient.SqlException] {
    $ErrorDetails = Format-Error -Exception $_ -Depth 2

    switch -Wildcard ($ErrorDetails.Exception.Message) {
        '*The server was not found or was not accesible.*' {
            Write-Error "Connection to the database server failed." -ErrorAction Continue
            exit [ExitCodes]::DatabaseConnectionFailed
        }
        'Login failed for user*' {
            Write-Error "Login to the database server failed." -ErrorAction Continue
            exit [ExitCodes]::DatabaseLoginFailed
        }
        'Cannot open database*requested by the login. The login failed.*' {
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
finally {
    if ($ErrorDetails) {
        
        $errorOutputPath = "${PSScriptRoot}\errors\StackTrace_$timestamp.txt"
        $ErrorDetails | Out-File $errorOutputPath 
    }
}