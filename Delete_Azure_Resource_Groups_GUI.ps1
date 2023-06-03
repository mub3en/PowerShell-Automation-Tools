#Change Set Execution policy if unable to execute the script.
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

############################################################
#Uncomment this block and provide correct parameters if Powershell is not configured locally or in cloud.
# Import the Azure module
#Import-Module Az

# Set your Azure subscription
#Set-AzContext -SubscriptionId "YOUR_SUBSCRIPTION_ID"
############################################################

Add-Type -AssemblyName System.Windows.Forms

# Create a new instance of a form
$form = New-Object System.Windows.Forms.Form

# Set the form properties
$form.Text = "Azure Resource Groups"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create a label for the banner
$bannerLabel = New-Object System.Windows.Forms.Label
$bannerLabel.Text = "Select a group"
$bannerLabel.Location = New-Object System.Drawing.Point(100, 10)
$bannerLabel.Size = New-Object System.Drawing.Size(200, 40)

# Set the font to bold
$font = New-Object System.Drawing.Font($bannerLabel.Font, [System.Drawing.FontStyle]::Bold)
$bannerLabel.Font = $font

$form.Controls.Add($bannerLabel)

# Create a drop-down list control
$dropDownList = New-Object System.Windows.Forms.ComboBox
$dropDownList.Location = New-Object System.Drawing.Point(100, 50)
$dropDownList.Size = New-Object System.Drawing.Size(200, 20)
$dropDownList.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

# Collect resource group names using Get-AzResourceGroup
$resourceGroups = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName

# Add resource group names to the drop-down list
$dropDownList.Items.AddRange($resourceGroups)

# Define the event handler for the drop-down list selection change
$dropDownList.Add_SelectedIndexChanged({
    $selectedItem = $dropDownList.SelectedItem.ToString()
    $bannerLabel.Text = "SELECTED: $selectedItem"
    
    # Prompt for confirmation to delete the resource group
    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete the resource group '$selectedItem'?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    
    if ($result -eq "Yes") {
        try {
            # Disable the drop-down list
            $dropDownList.Enabled = $false
            
            # Delete the resource group using Remove-AzResourceGroup
            Remove-AzResourceGroup -Name $selectedItem -Force
            
            # Show success message
            [System.Windows.Forms.MessageBox]::Show("Resource group '$selectedItem' has been successfully deleted.", "Deletion Success")
            
            #Update banner with the default text
            $bannerLabel.Text = "Select a group"

            # Update the drop-down list by removing the deleted resource group
            $dropDownList.Items.Remove($selectedItem)
        }
        catch {
            # Show failure message
            [System.Windows.Forms.MessageBox]::Show("Failed to delete the resource group '$selectedItem'.", "Deletion Failed")
        }
        finally {
            # Enable the drop-down list
            $dropDownList.Enabled = $true
        }
    }
})

# Add the drop-down list control to the form
$form.Controls.Add($dropDownList)

# Show the form
$form.ShowDialog()
