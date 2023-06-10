#This function helps you formatting error. It takes an exception object, extracts relevant information from it, 
#and organizes it into a structured format for easier error reporting and analysis.
function Format-Error {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [Alias("Exception")]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord,
        [Switch]
        $IncludeInnerExceptions
    )

    process {
        $errorDetails = [ordered]@{
            Reason = [ordered]@{}
            Exception = [ordered]@{}
            ScriptStackTrace = $ErrorRecord.ScriptStackTrace
            InvocationInfo = $ErrorRecord.InvocationInfo
        }

        $exception = $ErrorRecord.Exception
        $errorDetails.Exception.Source = $exception.Source
        $errorDetails.Exception.Message = $exception.Message
        $errorDetails.Exception.ErrorCode = $exception.ErrorCode

        $errorDetails.ExceptionText = "======== Exception: ========"
        $errorDetails.ExceptionText += "`n{0} - {1}`n" -f $exception.ErrorCode, $exception.Message

        if ($IncludeInnerExceptions -and $exception.InnerException) {
            $innerException = $exception.InnerException
            $i = 1

            while ($innerException) {
                $errorDetails["InnerException$i"] = [ordered]@{
                    Message = $innerException.Message
                    ErrorCode = $innerException.ErrorCode
                }

                $errorDetails.ExceptionText += "======== InnerException ${i}: ========"
                $errorDetails.ExceptionText += "`n{0} - {1}`n" -f $innerException.ErrorCode, $innerException.Message

                $innerException = $innerException.InnerException
                $i++
            }
        }

        [PSCustomObject]$errorDetails
    }
}


function Get-SqlServerInfo {
    param()
    
    $SQLServerName = Read-Host 'Input the SQL Server Name '
    $SQLInstance = Read-Host 'Input the SQL Instance Name, if any - Hit Enter if empty '
    $SQLDatabaseName = Read-Host 'Input the SQL Database Name '
    $SQLLogin = Get-Credential
    
    $SQLServerInstance = if ([string]::IsNullOrEmpty($SQLInstance)) {
        $SQLServerName
    }
    else {
        "{0}\{1}" -f $SQLServerName, $SQLInstance
    }
    
    return @{
        SQLServerName = $SQLServerName
        SQLInstance = $SQLInstance
        SQLDatabaseName = $SQLDatabaseName
        SQLLogin = $SQLLogin
        SQLServerInstance = $SQLServerInstance
    }
}
