function Format-Error {
    [CmdletBinding()]
    param(
        [Alias("Exception")]
        $e = $Error[0],
        $Recurse = $true,
        $Depth =2
    )

    $Details = [ordered]@{}
    $Details.Reason = @{}
    $Details.ScriptStackTrace = $e.ScriptStackTrace
    $Details.InvocationInfo = $e.InvocationInfo

    $Exception = $e.Exception
    $Details.Exception = @{}
    $Details.Exception.Source = $Exception.Source
    $Details.Exception.Message = $Exception.Message
    $Details.xception.ErrorCode = $Exception.ErrorCode 

    $ExceptionText = "========Exception: 0`n"
    $ExceptionText += ("{0} - {1} `n" -f $Exception.ErrorCode, $Exception.Message)

    if($Recurse){
        for ($i=1; $i -le $Depth; Si++) {
            if ( -not [string]::ISNullOrEmpty( ("{0}{1)"-f $Exception.Message, $Exception.ErrorCode) )) {
                $Details."InnerException${i}" = @{}
                $Details."InnerException${i}".Message = $Exception.Message
                $Details."InnerException${i}".ErrorCode = $Exception.ErrorCode
                $ExceptionText += ("========InnerException: {0}`n" -f $i)
                $ExceptionText += ("{0} {1} `n" -f $Exception.ErrorCode, $Exception.Message)
            }
        }
    }
    $Details.ExceptionText = $ExceptionText
    return [PSCustomObject]$Details
}