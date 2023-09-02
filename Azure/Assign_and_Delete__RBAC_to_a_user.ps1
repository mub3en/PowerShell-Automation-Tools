#get identity of the current user and verify if its an administrator 
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$TestAdmin = (New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if ($TestAdmin -eq $false) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($MyInvocation.MyCommand.Definition))
    exit $LASTEXITCODE
}

# Define the path to the JSON file on your local desktop
$jsonFilePath = Join-Path $env:USERPROFILE
#Provide path parameter to the cmdlet: \<YOUR_DIRECTORY>\<YOUR_ARM_FILE>.json

# Check if the JSON file exists
if (Test-Path $jsonFilePath) {
    # Create the custom role definition using the JSON file
    New-AzRoleDefinition -InputFile $jsonFilePath
} else {
    Write-Error "The JSON file '$jsonFilePath' does not exist."
}


#Delete access to the user and the role
try {
    # Get the custom role definition and assignable scopes
    $roleDefinition = Get-AzRoleDefinition -Name 'Support Request Contributor (Custom)'
    
    if ($roleDefinition -ne $null) {
        $scopes = $roleDefinition.AssignableScopes | Where-Object {$_ -like '*managementgroup*'}
        
        if ($scopes.Count -gt 0) {
            # Define the object ID of the user or service principal to remove the role assignment from
            $objectId = '<USER_ID>'
            
            # Remove the role assignment
            Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName 'Support Request Contributor (Custom)' -Scope $scopes 
            
            Write-Host "Role assignment removed successfully for object ID: $objectId"
            
            # Remove the custom role definition if the role assignment removal is successful
            Remove-AzRoleDefinition -Name 'Support Request Contributor (Custom)' -Force
            Write-Host "Custom role definition 'Support Request Contributor (Custom)' removed successfully."
        } else {
            Write-Warning "No assignable scopes with 'managementgroup' in their name were found for the custom role."
        }
    } else {
        Write-Warning "The custom role 'Support Request Contributor (Custom)' was not found."
    }
} catch {
    Write-Error "An error occurred: $_.Exception.Message"
}