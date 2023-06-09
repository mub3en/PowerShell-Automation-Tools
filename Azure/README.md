# Azure Automation via PowerShell

These PowerShell scripts provide assistance with automating tasks like Adding multiple ResourceGroup, Deleting Single or Multiple ResourceGroups, Adding Azure SQL Database and the Server it depends on.

## Prerequisites

- PowerShell with Azure PowerShell module (`Az`) installed and configured.
- Permission to delete resource groups in the Azure subscription.

## How to Use `Delete_Azure_Resource_Groups_GUI.ps1`

1. Open PowerShell or PowerShell ISE.
2. Copy and run the code from the script file (`Delete_Azure_Resource_Groups_GUI.ps1`) in this repository.
3. The script will launch a Windows Forms GUI window.
4. The drop-down list will display the names of all the available resource groups in your Azure subscription.
5. Select a resource group from the drop-down list.
6. A confirmation message box will appear to confirm the deletion.
7. Click "Yes" to proceed with the deletion or "No" to cancel.
8. If "Yes" is selected, the script will attempt to delete the selected resource group.
9. If the deletion is successful, a success message will be displayed.
10. If the deletion fails, an error message will be displayed.
11. The drop-down list will be updated to remove the deleted resource group.
12. Repeat the process to delete additional resource groups if needed.


## How to Use `Create_Azure_SQL_Server_and_DB_GUI.ps1`
1. Open a PowerShell terminal or the PowerShell ISE.
2. Set the execution policy to 'Bypass' by running the following command:

```PowerShell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
3. Import the required modules by running the script. This will import the necessary functions and types used by the script.
4. Run the script. A GUI window will open, allowing you to configure the SQL Database provisioning settings.
5. Select a resource group from the drop-down list.
6. Select a location from the drop-down list.
7. Enter the server name, username, password, database name, and select the database edition.
8. Click the "Preview Config" button to review the configuration details.
9. If all the required fields are filled, a message box will display the configuration details.
10. Click "Yes" to proceed with the server and database creation.
11. The script will disable the input fields and display informational message boxes during the provisioning process.
12. Once the process is complete, a final message box will indicate the success or failure of the provisioning.

## Notes

- This tool is designed for deleting Azure resource groups only. Exercise caution when using it to avoid unintended deletions.
- Make sure you have appropriate permissions to delete resource groups in your Azure subscription.
- The tool utilizes the `Remove-AzResourceGroup` cmdlet, which permanently deletes the specified resource group and all the resources contained within it. Be mindful of the consequences before confirming the deletion.

