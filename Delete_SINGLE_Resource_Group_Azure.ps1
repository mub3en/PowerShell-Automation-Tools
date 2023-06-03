# Import the Azure module
#Import-Module Az

# Set your Azure subscription
#Set-AzContext -SubscriptionId "YOUR_SUBSCRIPTION_ID"

# Prompt the user for the resource group name to delete
$resourceGroupName = Read-Host -Prompt "Enter the name of the resource group to delete"

# Define a variable to track the deletion status
$deletionSuccessful = $false

try {
    # Delete the resource group
    Remove-AzResourceGroup -Name $resourceGroupName -Force
    $deletionSuccessful = $true
} catch {
    Write-Host "An error occurred while deleting the resource group: $($_.Exception.Message)"
}

# Display the appropriate message based on the deletion status
if ($deletionSuccessful) {
    Write-Host "Resource group '$resourceGroupName' deleted successfully."
} else {
    Write-Host "Failed to delete resource group '$resourceGroupName'."
}
