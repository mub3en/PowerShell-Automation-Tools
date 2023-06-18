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

function Save-DataTableToHtmlTable{
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


function Save-CSVtoHtmlTable {
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The label of the report.")]
        [string]$ReportLabel,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The CSV object containing the data.")]
        [object[]]$CsvObject,

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
    $htmlContent += "<div><h1 style='text-align: center;'>$ReportLabel</h1></div>"
    $htmlContent += "<table border='1'>"
    $htmlContent += "<thead>"
    $htmlContent += "<tr bgcolor='#99CC33'>"
    $htmlContent += ($CsvObject[0].PSObject.Properties.Name | ForEach-Object { "<th>$_</th>" }) -join ""
    $htmlContent += "</tr>"
    $htmlContent += "</thead>"
    $htmlContent += "<tbody>"
    foreach ($row in $CsvObject) {
        $htmlContent += "<tr>"
        $rowValues = $row.PSObject.Properties.Value | ForEach-Object { "<td>$_</td>" }
        $htmlContent += $rowValues -join ""
        $htmlContent += "</tr>"
    }
    $htmlContent += "</tbody>"
    $htmlContent += "</table>"
    $htmlContent += "</body>"

    $htmlContent | Out-File -FilePath $OutputFilePath
}

function Save-PSCustomObjToHtmlTable {
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The label of the report.")]
        [string]$ReportLabel,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The PS custom object that contains the data.")]
        [PSCustomObject]$CustomPSObject,

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
    $htmlContent += ($CustomPSObject.PSObject.Properties.Name | ForEach-Object { "<th>$($_)</th>" }) -join ""
    $htmlContent += "</tr>"
    $htmlContent += "</thead>"
    $htmlContent += "<tbody>"
    $maxRowCount = $CustomPSObject.PSObject.Properties.Value | ForEach-Object { $_.Count } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    for ($i = 0; $i -lt $maxRowCount; $i++) {
        $htmlContent += "<tr>"
        foreach ($property in $CustomPSObject.PSObject.Properties) {
            $propertyValue = $property.Value
            if ($propertyValue -is [System.Array]) {
                if ($i -lt $propertyValue.Length) {
                    $htmlContent += "<td>$($propertyValue[$i])</td>"
                } else {
                    $htmlContent += "<td></td>"
                }
            } else {
                $htmlContent += "<td>$propertyValue</td>"
            }
        }
        $htmlContent += "</tr>"
    }
    $htmlContent += "</tbody>"
    $htmlContent += "</table>"
    $htmlContent += "</body>"

    $htmlContent | Out-File -FilePath $OutputFilePath
}

function Save-ToTextFile {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Object]$Object,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    $Object | Out-File -FilePath $FilePath -Encoding UTF8 
}

# function DisplayTable($title, $data) {
#     Write-Host
#     Write-Host $title
#     Write-Host ('-' * $title.Length)
    
#     $maxNameLength = ($data | Measure-Object { $_.Name.Length } -Maximum).Maximum
    
#     $data | ForEach-Object {
#         $name = $_.Name
#         $value = $_.Value
        
#         if ($value -is [System.Management.Automation.PSCustomObject]) {
#             $value = ExtractProperties $value
#         }
        
#         $padding = ' ' * ($maxNameLength - $name.Length)
#         Write-Host ("{0}:{1}{2}" -f $name, $padding, $value)
#     }
# }

# function ExtractProperties($obj) {
#     $properties = $obj | Get-Member -MemberType Property | Select-Object -ExpandProperty Name
    
#     $result = foreach ($property in $properties) {
#         $propertyValue = $obj.$property
#         if ($propertyValue -is [System.Management.Automation.PSCustomObject]) {
#             $propertyValue = ExtractProperties $propertyValue
#         }
#         "$propertyValue"
#     }
    
#     return $result -join ', '
# }