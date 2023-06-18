<#
Refernce article: https://learn.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps
#>
<#
.SYNOPSIS
There are two SQL Server PowerShell modules; SqlServer and SQLPS.

.DESCRIPTION
We are using all GET functions for this directory that makes it easy to retrieve all the necessary information.

.PARAMETER Requirements
1. Insufficient Windows permissions: If the user does not have sufficient Windows permissions`
 to access the SQL Server instance, you may receive an error message indicating that the user `
 is unable to establish a connection or authenticate to the server.

2. Insufficient SQL Server permissions: Even if the user has appropriate Windows permissions,`
they may still encounter an error if they do not have the required SQL Server permissions to`
access the SQL Server Agent information. In this case, you may receive an error message stating`
that the user does not have the necessary permissions to perform the requested operation.

####
Ensure that the user has the necessary Windows permissions to access the SQL Server instance. This typically involves being a member of a Windows security group that has been granted appropriate access to the SQL Server.

Verify that the user has the required SQL Server permissions to access the SQL Server Agent information. This can involve granting the user specific permissions within SQL Server, such as VIEW SERVER STATE or specific permissions on SQL Server Agent objects.

If necessary, contact the database administrator or system administrator responsible for the SQL Server instance to request the required permissions.
####


To authenticate with SQL Server authentication, you need to provide the appropriate parameters`
when specifying the -ServerInstance parameter in the Get-SqlAgent cmdlet. Here's an example:
PS> Get-SqlAgent -ServerInstance "ServerName" -Credential (Get-Credential -UserName "YourUsername" -Message "Enter your SQL Server password")


#>

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
        SQLServerName     = $SQLServerName
        SQLInstance       = $SQLInstance
        SQLDatabaseName   = $SQLDatabaseName
        SQLLogin          = $SQLLogin
        SQLServerInstance = $SQLServerInstance
    }
}

<#
.SYNOPSIS
Gets a SQL Agent object that is present in the target instance of SQL Server.

.EXAMPLE
PS> Get-CustomSqlAgent -ServerInstance "ServerName"
OR
PS> Get-CustomSqlAgent -ServerInstance "ServerName" -ShortSummary $false
Retrieves complete SQL Server Agent information for the specified server instance 'ServerName'.
#>
function Get-CustomSqlAgent {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$ServerInstance,
        
        [Parameter()]
        [bool]$DefaultProperties = $true
    )
    Process {
        $defaultSelectedProperties = @(
            "AgentDomainGroup"
            , "AgentLogLevel"
            , "AgentMailType"
            , "ErrorLogFile"
            , "JobServerType"
            , "ServiceAccount"
            , "Operators"
            , "Jobs"
            , "ServerVersion"
            , "DatabaseEngineEdition"
            , "State"
        )

        $agent = $null  # Initialize the $output variable

        if ($DefaultProperties) {
            $agent = Get-SqlAgent -ServerInstance $ServerInstance | Select-Object -Property $defaultSelectedProperties

            foreach ($property in $defaultSelectedProperties) {
                $propertyValue = $agent.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $agent.$property = $names -join ', '
                }
            }
        }
        else {
            $agent = Get-SqlAgent -ServerInstance $ServerInstance | Select-Object -Property *
            $agent | Get-Member -MemberType Properties | ForEach-Object {
                $property = $_.Name
                $propertyValue = $agent.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $agent.$property = $names -join ', '
                }
            }
        }

        return $agent
    }
}


<#
.SYNOPSIS
Gets a SQL Agent Job object for each job that is present in the target instance of SQL Agent.

.EXAMPLE
PS> Get-CustomSqlAgentJob -ServerInstance "ServerName"
OR
PS> Get-CustomSqlAgentJob -ServerInstance "ServerName" -Name $false
Retrieves complete SQL Server Agent information for the specified server instance 'ServerName'.
#>

# function Get-CustomSqlAgentJob {
#     [CmdletBinding()]
#     param (
#         [Parameter(Position = 0, Mandatory = $true)]
#         [String]$ServerInstance,
        
#         [Parameter(Position = 1, Mandatory = $false)]
#         [String]$JobName,
        
#         [Parameter(Position = 2, Mandatory = $false)]
#         [bool]$DefaultProperties = $true
#     )
#     Process {
#         if (-not [string]::IsNullOrEmpty($JobName)) {
#             $job = Get-SqlAgentJob -ServerInstance $ServerInstance -Name $JobName
#         } else {
#             $job = Get-SqlAgentJob -ServerInstance $ServerInstance
#         }

#         # Create a custom PSObject with selected properties from $job
#         $customObject = [PSCustomObject]@{}

#         if ($DefaultProperties) {
#             $selectedProperties = @(
#                 "Name",
#                 "OwnerLoginName",
#                 "Category",
#                 "IsEnabled",
#                 "CurrentRunStatus",
#                 "DateCreated",
#                 "LastRunDate",
#                 "LastRunDuration"
#             )
#         } else {
#             $selectedProperties = $job | Get-Member -MemberType Property | ForEach-Object { $_.Name }
#         }

#         foreach ($propertyName in $selectedProperties) {
#             $propertyValue = $job.$propertyName
#             $customObject | Add-Member -MemberType NoteProperty -Name $propertyName -Value $propertyValue
#         }

#         return $customObject
#     }
# }


function Get-CustomSqlAgentJob {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$ServerInstance,
        
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$JobName,
        
        [Parameter(Position = 2, Mandatory = $false)]
        [bool]$DefaultProperties = $true
    )
    Process {
        $defaultSelectedProperties = @(
            "Name",
            "OwnerLoginName",
            "Category",
            "IsEnabled",
            "CurrentRunStatus",
            "DateCreated",
            "LastRunDate",
            "LastRunDuration"
        )

        $job = $null
        if (-not [string]::IsNullOrEmpty($JobName)) {
            $job = Get-SqlAgentJob -ServerInstance $ServerInstance -Name $JobName
        }
        else {
            $job = Get-SqlAgentJob -ServerInstance $ServerInstance
        }

        if ($DefaultProperties) {
            $job = $job | Select-Object -Property $defaultSelectedProperties
            foreach ($property in $defaultSelectedProperties) {
                $propertyValue = $job.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $job.$property = $names -join ', '
                }
            }
        }
        else {
            $job = $job | Select-Object -Property *
            $job | Get-Member -MemberType Properties | ForEach-Object {
                $property = $_.Name
                $propertyValue = $job.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $job.$property = $names -join ', '
                }
            }
        }
        return $job
    }
}
