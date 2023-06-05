Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules\functions.psm1'
Import-Module -Name $modulePath #-Verbose

Add-Type -AssemblyName System.Windows.Forms

#Pre defined variables
$global:selectedResGrp = $null
$global:selectedLocation = $null
$global:enteredServerName = $null
$global:enteredUserName = $null
$global:enteredPwd = $null

# Create a new instance of a form
$form = New-Object System.Windows.Forms.Form 
$form.StartPosition = 'CenterScreen'

# Set the form properties
$form.Text = "Azure SQL Database"
$form.Size = New-Object System.Drawing.Size(400, 900)

################################################################################
######################### Resource Groups drop down list ####################### 
################################################################################
$bannerLabelResgrp = New-FormLabel -LabelText "Select a Resource Group" -LabelLocation (New-Object System.Drawing.Point(70, 10))

$form.Controls.Add($bannerLabelResgrp)

# Collect resource group names using Get-AzResourceGroup
$resourceGroups = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName

$dropDownListResGrps = New-FormDropDownList -DropDownLocation (New-Object System.Drawing.Point(70, 30)) -DropDownItems @($resourceGroups)
# Add the drop-down list control to the form
$form.Controls.Add($dropDownListResGrps)

# Define the event handler for the drop-down list selection change
$dropDownListResGrps.Add_SelectedIndexChanged({
    $selectedResGrp = $dropDownListResGrps.SelectedItem.ToString()
    $global:selectedResGrp =  $selectedResGrp 
})

################################################################################
######################### Region Locations drop down list ###################### 
################################################################################
$bannerLabelLocation = New-FormLabel -LabelText "Select a Location" -LabelLocation (New-Object System.Drawing.Point(70, 60))
$form.Controls.Add($bannerLabelLocation)

# Array of locations for the dropdown list
$locations = @("eastus", "eastus1", "westus")

# Create the second dropdown list
$dropDownListLocations = New-FormDropDownList -DropDownLocation (New-Object System.Drawing.Point(70, 80)) -DropDownItems @($locations)
$form.Controls.Add($dropDownListLocations)

# Define the event handler for the second dropdown list selection change
$dropDownListLocations.Add_SelectedIndexChanged({
    $selectedLocation = $dropDownListLocations.SelectedItem.ToString()
    $global:selectedLocation=  $selectedLocation 
})

# Add the drop-down list control to the form
$form.Controls.Add($dropDownListLocations)

################################################################################
############### Add Server Name that will host SQL database #################### 
################################################################################
$bannerLabelServerName = New-FormLabel -LabelText "Enter Server Name" -LabelLocation (New-Object System.Drawing.Point(70, 110))
$form.Controls.Add($bannerLabelServerName)

$inputFieldServerName = New-TextInputField -TextInputLocation (New-Object System.Drawing.Point(70, 130))

# Event handler for TextChanged event
$inputFieldServerName.add_TextChanged({
    $enteredServerName = $inputFieldServerName.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($enteredServerName)) {
        $bannerLabelServerName.Text = "Enter Server Name"
    }
    elseif($enteredServerName.Length -gt 1){
        if ($enteredServerName -cmatch '^[a-z0-9][a-z0-9-]*[a-z0-9]$') {
            # $bannerLabelServerName.Text = "Entered: $enteredServerName"
            $global:enteredServerName = $enteredServerName
        }
        else {
            $bannerLabelServerName.Text = "Invalid Server Name: $enteredServerName"
            [System.Windows.Forms.MessageBox]::Show("Invalid Server Name: ($enteredServerName) `nBetween 1 and 63 characters long.`nOnly Lowercase letters, numbers and hyphens.`nSQL Server Logical name must be globally Unique. ", "Error")
        }
    }
})

$form.Controls.Add($inputFieldServerName)

################################################################################
############### Add User Name for the SQL Sever #################### 
################################################################################
$bannerLabelUserName = New-FormLabel -LabelText "Enter User Name" -LabelLocation (New-Object System.Drawing.Point(70, 160))
$form.Controls.Add($bannerLabelUserName)

# Create the input field
$inputFieldUserName = New-TextInputField -TextInputLocation (New-Object System.Drawing.Point(70, 180))

# Event handler for TextChanged event
$inputFieldUserName.add_TextChanged({
    $enteredUserName = $inputFieldUserName.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($enteredUserName)) {
        $bannerLabelUserName.Text = "Enter User Name"
    }
    elseif($enteredUserName.Length -gt 1){
        if ($enteredUserName -cmatch '^[a-zA-Z0-9.]+$') {
            # $bannerLabelUserName.Text = "Entered: $enteredUserName"
            $global:enteredUserName = $enteredUserName
        }
        else {
            $bannerLabelUserName.Text = "Invalid User Name: $enteredUserName"
            [System.Windows.Forms.MessageBox]::Show("Invalid user Name: ($enteredUserName) `nOnly  letters, numbers and  period.", "Error")
        }
    }
})

$form.Controls.Add($inputFieldUserName)

################################################################################
############### Add password for the SQL Sever #################### 
################################################################################
$bannerLabelPwd = New-FormLabel -LabelText "Enter Password" -LabelLocation (New-Object System.Drawing.Point(70, 210))
$form.Controls.Add($bannerLabelPwd)

# Create the input field
$inputFieldPwd = New-TextInputField -TextInputLocation (New-Object System.Drawing.Point(70, 230))

# Event handler for TextChanged event
$inputFieldPwd.add_TextChanged({
    $enteredPwd = $inputFieldPwd.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($enteredPwd)) {
        $enteredPwd.Text = "Enter Password"
    }
    elseif($enteredPwd.Length -gt 1){
        if ($enteredPwd -cmatch '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d|\W)(?!.*(.{3,}).*\1)[A-Za-z\d\W]{8,128}$' ) {
            # $bannerLabelPwd.Text = "Password is valid."
            $global:enteredPwd = $enteredPwd
        }
        else {
            # $bannerLabelPwd.Text = "Invalid Password: $enteredPwd"
            [System.Windows.Forms.MessageBox]::Show("Your password must be at least 8 characters in length.`nYour password must be no more than 128 characters in length.`nYour password must contain characters from three of the following categories `n
            English uppercase letters, English lowercase letters, numbers (0-9), `nand non-alphanumeric characters (!, $, #, %, etc.).`nYour password cannot contain all or part of the login name. `nPart of a login name is defined as three or more consecutive alphanumeric characters", "Error")
        }
    }
})

$form.Controls.Add($inputFieldPwd)

# Create the button
$buttonPreviewConfig = New-Object System.Windows.Forms.Button
$buttonPreviewConfig.Text = "Preview Config"
$buttonPreviewConfig.Location = New-Object System.Drawing.Point(70, 260)
$buttonPreviewConfig.Size = New-Object System.Drawing.Size(100, 30)

# Define the event handler for the button click event
$buttonPreviewConfig.Add_Click({
    $serverString = "New-AzureSqlServer -ResourceGroupName $global:selectedResGrp -ServerName $global:enteredServername -Location $global:selectedLocation -Username $global:enteredUserName -Password $global:enteredPwd `nAre you sure you want to create a new server?"

    $messageBoxButtons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $messageBoxIcon = [System.Windows.Forms.MessageBoxIcon]::Information

    $result = [System.Windows.Forms.MessageBox]::Show($serverString, "Configuration Preview", $messageBoxButtons, $messageBoxIcon)

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        # Code for 'Provision a Server' button
        [System.Windows.Forms.MessageBox]::Show("Server is getting created", "Information")
        try {
            $serverCreating = New-AzureSqlServerFunc -ResourceGroupName $global:selectedResGrp -ServerName $global:enteredServername -Location $global:selectedLocation -Username $global:enteredUserName -Password $global:enteredPwd
            # Check if the server was created successfully
            if ($serverCreating) {
                [System.Windows.Forms.MessageBox]::Show("Server created successfully", "Information")
            } else {
                [System.Windows.Forms.MessageBox]::Show("Server creation failed", "Error")
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error creating server: $($_.Exception.Message)", "Error")
        }
    } else {
        # Code for 'Cancel' button
    }
})

# Add the button to the form
$form.Controls.Add($buttonPreviewConfig)

# Show the form
$form.ShowDialog()