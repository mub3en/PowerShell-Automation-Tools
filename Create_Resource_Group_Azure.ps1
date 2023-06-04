#Change Set Execution policy if unable to execute the script.
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

############################################################
#Uncomment this block and provide correct parameters if Powershell is not configured locally or in cloud.
# Import the Azure module
#Import-Module Az

# Set your Azure subscription
#Set-AzContext -SubscriptionId "YOUR_SUBSCRIPTION_ID"
############################################################

# Prompt the user for resource group details
$resourceGroupName = Read-Host -Prompt "Enter the name of the resource group"
$location = Read-Host -Prompt "Enter the location of the resource group (e.g., eastus, westeurope, etc.)"

try {
    # Create the resource group
     $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
     if([string]::IsNullOrEmpty($resourceGroup)){
        Write-Host "There was an issue while creating the resource group."
     }else{
        Write-Host "Resource group '$($resourceGroup.ResourceGroupName)' created successfully."
     }
} catch {
    if ($_.Exception.Message -like "*AlreadyExists*") {
        Write-Host "Resource group '$resourceGroupName' already exists."
    } else {
        Write-Host "An error occurred while creating the resource group: $($_.Exception.Message)"
    }
}