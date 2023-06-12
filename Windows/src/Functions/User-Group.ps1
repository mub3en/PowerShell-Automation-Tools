function Get-Users {
    $users = Get-LocalUser
    return $users
}


function Get-Groups {
    $groups = Get-LocalGroup
    return $groups
}



# function Get-UserPolicy {
#     $users = Get-LocalUser
#     $groups = Get-LocalGroup

#     $userPolicies = Get-WmiObject -Class Win32_SystemAccount |
#         Select-Object -Property Name, SID, Caption, Domain, Disabled, Description, LocalAccount |
#         ForEach-Object {
#             $sid = $_.SID
#             $rights = Get-WmiObject -Class Win32_LogonSession |
#                 Where-Object { $_.AuthenticationPackage -ne 'NTLM' -and $_.AuthenticationPackage -ne 'Kerberos' } |
#                 Where-Object { $_.PSBase.Properties['PSComputerName'].Value -eq $env:COMPUTERNAME } |
#                 Where-Object { $_.PSBase.Properties['PSLogonId'].Value -match "^$sid" } |
#                 Select-Object -ExpandProperty PSLogonId |
#                 ForEach-Object {
#                     $logonId = $_
#                     Get-WmiObject -Class Win32_LogonSession |
#                         Where-Object { $_.AuthenticationPackage -ne 'NTLM' -and $_.AuthenticationPackage -ne 'Kerberos' } |
#                         Where-Object { $_.PSBase.Properties['PSComputerName'].Value -eq $env:COMPUTERNAME } |
#                         Where-Object { $_.PSBase.Properties['PSLogonId'].Value -eq $logonId } |
#                         Select-Object -ExpandProperty PSLogonId |
#                         ForEach-Object {
#                             $privileges = Get-WmiObject -Class Win32_LogonSession |
#                                 Where-Object { $_.AuthenticationPackage -ne 'NTLM' -and $_.AuthenticationPackage -ne 'Kerberos' } |
#                                 Where-Object { $_.PSBase.Properties['PSComputerName'].Value -eq $env:COMPUTERNAME } |
#                                 Where-Object { $_.PSBase.Properties['PSLogonId'].Value -eq $logonId } |
#                                 Select-Object -ExpandProperty PSPrivileges |
#                                 Select-Object -ExpandProperty PrivilegeCount |
#                                 ForEach-Object {
#                                     Get-WmiObject -Query "ASSOCIATORS OF {Win32_LogonSession.LogonId='$logonId'} WHERE ResultClass = Win32_UserPrivilegesSetting" |
#                                         Select-Object -ExpandProperty Privilege
#                                 }
#                             [PSCustomObject]@{
#                                 User = $_.Name
#                                 Privileges = $privileges
#                             }
#                         }
#                 }
#             [PSCustomObject]@{
#                 Account = $_.Name
#                 UserRights = $rights
#             }
#         }

#     $usersAndGroups = @{
#         Users = $users
#         Groups = $groups
#         UserPolicies = $userPolicies
#     }

#     return $usersAndGroups
# }




# function Get-UserPolicy {
#     $userPolicies = Get-WmiObject -Class Win32_UserAccount |
#         Select-Object -Property Name, SID |
#         ForEach-Object {
#             $sid = $_.SID
#             $userRights = Get-WmiObject -Class Win32_SystemAccount |
#                 Where-Object { $_.SID -eq $sid } |
#                 ForEach-Object {
#                     $userName = $_.Name
#                     Get-WmiObject -Class Win32_LogonSession |
#                         Where-Object { $_.PSBase.Properties['PSComputerName'].Value -eq $env:COMPUTERNAME -and $_.PSBase.Properties['PSLogonId'].Value -match "^$sid" } |
#                         ForEach-Object {
#                             $logonId = $_.PSBase.Properties['PSLogonId'].Value
#                             Get-WmiObject -Class Win32_UserPrivilegesSetting |
#                                 Where-Object { $_.PSBase.Properties['PSComputerName'].Value -eq $env:COMPUTERNAME -and $_.PSBase.Properties['PSLogonId'].Value -eq $logonId } |
#                                 Select-Object -ExpandProperty Privilege
#                         } | Select-Object -Unique
#                 }
#             [PSCustomObject]@{
#                 Account = $_.Name
#                 UserRights = $userRights -join ', '
#             }
#         }
#     return $userPolicies
# }

