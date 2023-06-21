<#
Refernce article: https://learn.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps
#>
<#
.SYNOPSIS
There are two SQL Server PowerShell modules; SqlServer and SQLPS.

.DESCRIPTION
We are utilizing various GET functions in this script to facilitate the retrieval of all the required information. By using these functions, we can easily gather the necessary data from the specified directory.

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

<#
.SYNOPSIS
Authenticates targeted SQL Server instance.

.EXAMPLE
PS> $serverInfo = Get-SqlServerInfo
-ServerInstance $serverInfo.SQLServerInstance 
-Database $serverInfo.SQLDatabaseName 
-Credential $serverInfo.SQLLogin
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
PS> Get-CustomSqlAgentJob -ServerInstance "ServerName" -JobName "JOB NAME" -DefaultProperties $false
#>
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

<#
.SYNOPSIS
Gets the job history present in the target instance of SQL Agent.

.EXAMPLE
PS> Get-CustomSqlAgentJob -ServerInstance "ServerName"
OR
PS> Get-CustomSqlAgentJob -ServerInstance "ServerName" -JobID "JOB NAME" -Since "LastWeek" -DefaultProperties $false

-Since
Midnight (gets all the job history information generated after midnight)
Yesterday (gets all the job history information generated in the last 24 hours)
LastWeek (gets all the job history information generated in the last week)
LastMonth (gets all the job history information generated in the last month)
#>
function Get-CustomSqlAgentJobHistory {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$ServerInstance,
        
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$JobID,

        [Parameter(Position = 2, Mandatory = $false)]
        [String]$Since = "LastWeek",
        
        [Parameter(Position = 3, Mandatory = $false)]
        [bool]$DefaultProperties = $true
    )
    Process {
        $defaultSelectedProperties = @(
            "SqlMessageID"     
            ,"InstanceID"
            ,"StepID"
            ,"JobID"
            ,"JobName"
            ,"StepName"         
            ,"Message"          
            ,"SqlSeverity"     
            ,"RunStatus"        
            ,"RunDate"          
            ,"RunDuration"      
            ,"OperatorEmailed" 
            ,"OperatorPaged"    
            ,"OperatorNetsent"  
            ,"RetriesAttempted" 
            ,"Server" 
        )

        $jobHistory = $null
        if (-not [string]::IsNullOrEmpty($JobID)) {
            $jobHistory = Get-SqlAgentJobHistory -ServerInstance $ServerInstance -Since $Since -JobID $JobID
        }
        else {
            $jobHistory = Get-SqlAgentJobHistory -ServerInstance $ServerInstance -Since $Since
        }

        if ($DefaultProperties) {
            $jobHistory = $jobHistory | Select-Object -Property $defaultSelectedProperties
            foreach ($property in $defaultSelectedProperties) {
                $propertyValue = $jobHistory.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $jobHistory.$property = $names -join ', '
                }
            }
        }
        else {
            $jobHistory = $jobHistory | Select-Object -Property *
            $jobHistory | Get-Member -MemberType Properties | ForEach-Object {
                $property = $_.Name
                $propertyValue = $jobHistory.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $jobHistory.$property = $names -join ', '
                }
            }
        }
        return $jobHistory
    }
}

<#
.SYNOPSIS
Gets a job schedule object for each schedule that is present in the target instance of SQL Agent Job

.EXAMPLE
PS> Get-CustomSqlAgentJobSchedule -ServerInstance "ServerName"
OR
PS> Get-CustomSqlAgentJobSchedule -ServerInstance "ServerName" -ScheduleName "JOB NAME"  -DefaultProperties $false
#>
function Get-CustomSqlAgentJobSchedule {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$ServerInstance,
        
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$ScheduleName,

        [Parameter(Position = 2, Mandatory = $false)]
        [bool]$DefaultProperties = $true
    )
    Process {
        $defaultSelectedProperties = @(
            "ID"
            ,"FrequencyInterval"  
            ,"Name"                           
            ,"IsEnabled"    
            ,"DateCreated"               
            ,"ActiveStartDate"           
            ,"ActiveEndDate"  
        )
                   
        $jobSchedule = $null
        if (-not [string]::IsNullOrEmpty($ScheduleName)) {
            $jobSchedule = Get-SqlAgentJob -ServerInstance $ServerInstance | Get-SqlAgentJobSchedule -Name $ScheduleName
        }
        else {
            $jobSchedule = Get-SqlAgentJob -ServerInstance $ServerInstance | Get-SqlAgentJobSchedule 
        }

        if ($DefaultProperties) {
            $jobSchedule = $jobSchedule | Select-Object -Property $defaultSelectedProperties
            foreach ($property in $defaultSelectedProperties) {
                $propertyValue = $jobSchedule.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $jobSchedule.$property = $names -join ', '
                }
            }
        }
        else {
            $jobSchedule = $jobSchedule | Select-Object -Property *
            $jobSchedule | Get-Member -MemberType Properties | ForEach-Object {
                $property = $_.Name
                $propertyValue = $jobSchedule.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $jobSchedule.$property = $names -join ', '
                }
            }
        }
        return $jobSchedule
    }
}

<#
.SYNOPSIS
Gets a job schedule object for each schedule that is present in the target instance of SQL Agent Job

.EXAMPLE
PS> Get-CustomSqlAgentJobSchedule -ServerInstance "ServerName"
OR
PS> Get-CustomSqlAgentJobSchedule -ServerInstance "ServerName" -StepName "Step NAME"  -DefaultProperties $false
#>
function Get-CustomSqlAgentJobSteps {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$ServerInstance,
        
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$StepName,

        [Parameter(Position = 2, Mandatory = $false)]
        [bool]$DefaultProperties = $true
    )
    Process {
        $defaultSelectedProperties = @(
            "Name"            
            ,"OnSuccessAction"           
            ,"OnFailAction"              
            ,"LastRunDate"              
            ,"LastRunDuration" 
            ,"ID"         
            ,"SubSystem" 
        )
   
        $jobsteps = $null
        if (-not [string]::IsNullOrEmpty($StepName)) {
            $jobsteps = Get-SqlAgent -ServerInstance $ServerInstance | Get-SqlAgentJob | Get-SqlAgentJobStep -Name $StepName
        }
        else {
            $jobsteps = Get-SqlAgent -ServerInstance $ServerInstance | Get-SqlAgentJob | Get-SqlAgentJobStep
        }

        if ($DefaultProperties) {
            $jobsteps = $jobsteps | Select-Object -Property $defaultSelectedProperties
            foreach ($property in $defaultSelectedProperties) {
                $propertyValue = $jobsteps.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $jobsteps.$property = $names -join ', '
                }
            }
        }
        else {
            $jobsteps = $jobsteps | Select-Object -Property *
            $jobsteps | Get-Member -MemberType Properties | ForEach-Object {
                $property = $_.Name
                $propertyValue = $jobsteps.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $jobsteps.$property = $names -join ', '
                }
            }
        }
        return $jobsteps
    }
}

<#
.SYNOPSIS
Gets a SQL job schedule object for each schedule that is present in the target instance of SQL Agent.

.EXAMPLE
PS> Get-CustomSqlAgentSchedule  -ServerInstance "ServerName"
OR
PS> Get-CustomSqlAgentSchedule  -ServerInstance "ServerName" -JobName "Step NAME"  -DefaultProperties $false
#>
function Get-CustomSqlAgentSchedule {
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
            "ID" 
            ,"Name"            
            ,"JobCount"           
            ,"IsEnabled"              
            ,"DateCreated"              
            ,"ActiveStartDate" 
            ,"ActiveEndDate"         
            
        )
   
        $jobsteps = $null
        if (-not [string]::IsNullOrEmpty($JobName)) {
            $jobsteps = Get-SqlAgentSchedule -ServerInstance $ServerInstance | Where-Object { $_.Name -eq $StepName }
        }
        else {
            $jobsteps = Get-SqlAgentSchedule -ServerInstance $ServerInstance  
        }

        if ($DefaultProperties) {
            $jobsteps = $jobsteps | Select-Object -Property $defaultSelectedProperties
            foreach ($property in $defaultSelectedProperties) {
                $propertyValue = $jobsteps.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $jobsteps.$property = $names -join ', '
                }
            }
        }
        else {
            $jobsteps = $jobsteps | Select-Object -Property *
            $jobsteps | Get-Member -MemberType Properties | ForEach-Object {
                $property = $_.Name
                $propertyValue = $jobsteps.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $jobsteps.$property = $names -join ', '
                }
            }
        }
        return $jobsteps
    }
}


<#
.SYNOPSIS
Gets SQL Assessment best practice checks available for a chosen SQL Server object.

.EXAMPLE
PS> Get-CustomSqlAssessmentItem -ServerInstance "ServerName"
OR
PS> Get-CustomSqlAssessmentItem -ServerInstance "ServerName" -DefaultProperties $false
#>
function Get-CustomSqlAssessmentItem {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$ServerInstance,
        
        [Parameter(Position = 1, Mandatory = $false)]
        [bool]$DefaultProperties = $true
    )
    Process {
        $defaultSelectedProperties = @(
            "ID" 
            ,"Enabled"            
            ,"DisplayName"           
            ,"OriginName" 
            ,"OriginVersion"                     
        )
   
        $sqlAssessment = $null

        if ($DefaultProperties) {
            $sqlAssessment = Get-SqlInstance -ServerInstance $ServerInstance | Get-SqlAssessmentItem | Select-Object -Property $defaultSelectedProperties
            foreach ($property in $defaultSelectedProperties) {
                $propertyValue = $sqlAssessment.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $sqlAssessment.$property = $names -join ', '
                }
            }
        }
        else {
            $sqlAssessment = Get-SqlInstance -ServerInstance $ServerInstance | Get-SqlAssessmentItem | Select-Object -Property *
            $sqlAssessment | Get-Member -MemberType Properties | ForEach-Object {
                $property = $_.Name
                $propertyValue = $sqlAssessment.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $sqlAssessment.$property = $names -join ', '
                }
            }
        }
        return $sqlAssessment
    }
}

<#
.SYNOPSIS
Gets backup information about databases and returns SMO BackupSet objects for each Backup record found based on the parameters specified to this cmdlet.

.EXAMPLE
PS> Get-CustomSqlBackupHistory -ServerInstance "ServerName"
OR
PS> Get-CustomSqlBackupHistory -ServerInstance "ServerName" -DatabaseName "DB NAME"  -DefaultProperties $false
#>
function Get-CustomSqlBackupHistory {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$ServerInstance,
        
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$DatabaseName,

        [Parameter(Position = 2, Mandatory = $false)]
        [bool]$DefaultProperties = $true
    )
    Process {
        $defaultSelectedProperties = @(
            "MachineName" 
            ,"ServerName"            
            ,"DatabaseName"           
            ,"Name"      
            ,"BackupSetType"              
            ,"BackupStartDate" 
            ,"BackupFinishDate"
            ,"ExpirationDate"
        )
   
        $backupHistory = $null
        if (-not [string]::IsNullOrEmpty($DatabaseName)) {
            $backupHistory = Get-SqlBackupHistory -ServerInstance $ServerInstance -DatabaseName $DatabaseName
        }
        else {
            $backupHistory = Get-SqlBackupHistory -ServerInstance $ServerInstance 
        }

        if ($DefaultProperties) {
            $backupHistory = $backupHistory | Select-Object -Property $defaultSelectedProperties
            foreach ($property in $defaultSelectedProperties) {
                $propertyValue = $backupHistory.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $backupHistory.$property = $names -join ', '
                }
            }
        }
        else {
            $backupHistory = $backupHistory | Select-Object -Property *
            $backupHistory | Get-Member -MemberType Properties | ForEach-Object {
                $property = $_.Name
                $propertyValue = $backupHistory.$property
    
                if ($propertyValue -is [Microsoft.SqlServer.Management.Smo.ArrayListCollectionBase] -or $propertyValue -is [Microsoft.SqlServer.Management.Smo.SimpleObjectCollectionBase]) {
                    $names = $propertyValue | Select-Object -ExpandProperty Name
                    $backupHistory.$property = $names -join ', '
                }
            }
        }
        return $backupHistory
    }
}
