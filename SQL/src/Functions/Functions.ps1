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

function ConvertToHtmlTable {
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The label of the report.")]
        [string]$ReportLabel,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The DataTable containing the data.")]
        [System.Data.DataTable]$DataTable,

        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "The output file path for the HTML file.")]
        [string]$OutputFilePath
    )

    $htmlContent = "<head><style>"
    $htmlContent += "table, td, th {"
    $htmlContent += "border: 1px solid;"
    $htmlContent += "padding: 10px;"
    $htmlContent += "}"
    $htmlContent += "table {"
    $htmlContent += "text-align: center;"
    $htmlContent += "}"
    $htmlContent += "</style></head>"
    $htmlContent += "<body>"
    $htmlContent += "<div ><h1 text-align=`"center`">$ReportLabel</h1></div>"
    $htmlContent += "<table borderColor=`"#111111`" border=`"1`">"
    $htmlContent += "<thead>"
    $htmlContent += "<tr bgcolor=`"#99CC33`">"
    $htmlContent += ($DataTable.Columns.ColumnName | ForEach-Object {"<th>$($_)</th>"}) -Join ""
    $htmlContent += "</tr>"
    $htmlContent += "</thead>"
    $htmlContent += "<tbody>"
    foreach ($row in $DataTable.Rows) {
        $htmlContent += "<tr>"
        $rowValues = $row.ItemArray | ForEach-Object { "<td>$_</td>" }
        $htmlContent += $rowValues -join ""
        $htmlContent += "</tr>"
    }
    $htmlContent += "</tbody>"
    $htmlContent += "</table>"
    $htmlContent += "</body>"


    $htmlContent | Out-File -FilePath $OutputFilePath

    <#
    # If we dont mention -OutputAs inside Invoke-SqlCmd, we will have to format the object System.Data appropriatley to get column and header data.
    #$htmlContent += ( $scriptOutPut[0].PSObject.Properties | Where-Object {$_.Name -notin ('MaximumSectionSize', 'RowError', 'RowState', 'Table','ItemArray', 'HasErrors')} |  ForEach-Object {"<th>$($_.Name)</th>"}) -Join ""
    #         $htmlContent += "</tr>"
    #         foreach ($row in $scriptOutPut) {
    #             $htmlContent += "<tr>"
    #             $htmlContent += ($row.PSObject.Properties | Where-Object {$_.Name -eq 'ItemArray'} | ForEach-Object { "<td>$($_.Value)</td>" }) -Join ""
    #             $htmlContent += "</tr>"
    #         }
    #>
}

