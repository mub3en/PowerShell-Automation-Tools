#Setting execution policy to 'ByPass'
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted
#Importing modules
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules\functions.psm1'
Import-Module -Name $modulePath #-Verbose
Add-Type -AssemblyName System.Windows.Forms

#Pre defining global variables to provide to New-AZ... flags.
$global:selectedResGrp = $null
$global:selectedLocation = $null
$global:enteredServerName = $null
$global:enteredUserName = $null
$global:enteredPwd = $null
$global:enteredSQLDB = $null
$global:selectedDBEdition = $null

# Create a new instance of a form
$form = New-Object System.Windows.Forms.Form 
$form.StartPosition = 'CenterScreen'

# Set the form properties
$form.Text = "Azure SQL Database"
$form.Size = New-Object System.Drawing.Size(400, 900)

################################################################################
######################### Resource Groups drop down list ####################### 
################################################################################

#Creating banner for RG
$bannerLabelResgrp = New-FormLabel -LabelText "Select a Resource Group" -LabelLocation (New-Object System.Drawing.Point(70, 10))

# Collect resource group names using Get-AzResourceGroup
$resourceGroups = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName

# Create Resource Groups drop-down
$dropDownListResGrps = New-FormDropDownList -DropDownLocation (New-Object System.Drawing.Point(70, 30)) -DropDownItems @($resourceGroups)

# Define the event handler for the drop-down list selection change
$dropDownListResGrps.Add_SelectedIndexChanged({
    $selectedResGrp = $dropDownListResGrps.SelectedItem.ToString()
    $global:selectedResGrp =  $selectedResGrp 
    if ([string]::IsNullOrWhiteSpace($selectedResGrp)) {
        $bannerLabelResgrp.Text = "Select a Resource Group *"
    }
})

################################################################################
######################### Region Locations drop down list ###################### 
################################################################################

#Creating banner for Locations
$bannerLabelLocation = New-FormLabel -LabelText "Select a Location" -LabelLocation (New-Object System.Drawing.Point(70, 60))

# Array of locations for the drop-down list
$locations = @("eastus", "eastus1", "westus")

# Create Locations drop down
$dropDownListLocations = New-FormDropDownList -DropDownLocation (New-Object System.Drawing.Point(70, 80)) -DropDownItems @($locations)

# Define the event handler for the second drop-down list selection change
$dropDownListLocations.Add_SelectedIndexChanged({
    $selectedLocation = $dropDownListLocations.SelectedItem.ToString()
    $global:selectedLocation=  $selectedLocation 
    if ([string]::IsNullOrWhiteSpace($selectedLocation)) {
        $bannerLabelLocation.Text = "Select a Location *"
    }
})

################################################################################
############### Add Server Name that will host SQL database #################### 
################################################################################

#Creating banner for ServerName
$bannerLabelServerName = New-FormLabel -LabelText "Enter Server Name" -LabelLocation (New-Object System.Drawing.Point(70, 110))

$inputFieldServerName = New-TextInputField -TextInputLocation (New-Object System.Drawing.Point(70, 130))

# Event handler for TextChanged event
$inputFieldServerName.add_TextChanged({
    $enteredServerName = $inputFieldServerName.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($enteredServerName)) {
        $bannerLabelServerName.Text = "Enter Server Name *"
    }
    elseif($enteredServerName.Length -gt 1){
        if ($enteredServerName -cmatch '^[a-z0-9][a-z0-9-]*[a-z0-9]$') {
            # $bannerLabelServerName.Text = "Entered: $enteredServerName"
            $global:enteredServerName = $enteredServerName
        }
        else {
            # $bannerLabelServerName.Text = "Invalid Server Name: $enteredServerName"
            [System.Windows.Forms.MessageBox]::Show("Invalid Server Name: ($enteredServerName) `n* Between 1 and 63 characters long.`n* Only Lowercase letters, numbers and hyphens.`n* SQL Server Logical name must be globally Unique. ", "Error")
        }
    }
})

################################################################################
############### Add User Name for the SQL Sever #################### 
################################################################################

#Creating banner for UserName
$bannerLabelUserName = New-FormLabel -LabelText "Enter User Name" -LabelLocation (New-Object System.Drawing.Point(70, 160))

# Create the input field
$inputFieldUserName = New-TextInputField -TextInputLocation (New-Object System.Drawing.Point(70, 180))

# Event handler for TextChanged event
$inputFieldUserName.add_TextChanged({
    $enteredUserName = $inputFieldUserName.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($enteredUserName)) {
        $bannerLabelUserName.Text = "Enter User Name *"
    }
    elseif($enteredUserName.Length -gt 1){
        if ($enteredUserName -cmatch '^[a-zA-Z0-9.]+$') {
            # $bannerLabelUserName.Text = "Entered: $enteredUserName"
            $global:enteredUserName = $enteredUserName
        }
        else {
            # $bannerLabelUserName.Text = "Invalid User Name: $enteredUserName"
            [System.Windows.Forms.MessageBox]::Show("Invalid user Name: ($enteredUserName) `nOnly  letters, numbers and  period.", "Error")
        }
    }
})

################################################################################
############### Add password for the SQL Sever #################################
################################################################################

#Creating banner for Password
$bannerLabelPwd = New-FormLabel -LabelText "Enter Password" -LabelLocation (New-Object System.Drawing.Point(70, 210))

# Create the input field
$inputFieldPwd = New-TextInputField -TextInputLocation (New-Object System.Drawing.Point(70, 230))

# Event handler for TextChanged event
$inputFieldPwd.add_TextChanged({
    $enteredPwd = $inputFieldPwd.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($enteredPwd)) {
        $enteredPwd.Text = "Enter Password *"
    }
    elseif($enteredPwd.Length -gt 6){
        if ($enteredPwd -cmatch '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d|\W)(?!.*(.{3,}).*\1)[A-Za-z\d\W]{8,128}$' ) {
            # $bannerLabelPwd.Text = "Password is valid."
            $global:enteredPwd = $enteredPwd
        }
        else {
            # $bannerLabelPwd.Text = "Invalid Password: $enteredPwd"
            [System.Windows.Forms.MessageBox]::Show("* Your password must be at least 8 characters in length.`n* Your password must be no more than 128 characters in length.`n* Your password must contain characters from three of the following categories - `nEnglish uppercase letters, English lowercase letters, numbers (0-9), `nand non-alphanumeric characters (!, $, #, %, etc.).`n* Your password cannot contain all or part of the login name - `nPart of a login name is defined as three or more consecutive alphanumeric characters", "Error")
        }
    }
})

################################################################################
############### Add SQL Database Name  ######################################## 
################################################################################

#Creating banner for SQL Database
$bannerLabelSQLDB = New-FormLabel -LabelText "Enter Database Name" -LabelLocation (New-Object System.Drawing.Point(70, 260))

# Create the input field
$inputFieldSQLDB = New-TextInputField -TextInputLocation (New-Object System.Drawing.Point(70, 280))

# Event handler for TextChanged event
$inputFieldSQLDB.add_TextChanged({
    $enteredSQLDB = $inputFieldSQLDB.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($enteredSQLDB)) {
        $bannerLabelSQLDB.Text = "Enter Database Name *"
    }
    elseif($enteredSQLDB.Length -gt 1){
        if ($enteredSQLDB -cmatch '^[a-zA-Z0-9_]+$') {
            $global:enteredSQLDB = $enteredSQLDB
        }
        else {
            # $bannerLabelUserName.Text = "Invalid User Name: $enteredUserName"
            [System.Windows.Forms.MessageBox]::Show("Invalid user Name: ($enteredSQLDB) `nOnly  letters, numbers and underscore(_).", "Error")
        }
    }
})

################################################################################
######################### SQL Database Edition list ############################ 
################################################################################

#Creating banner for SQL Database
$bannerLabelDBEdition = New-FormLabel -LabelText "Select an Edition for the database" -LabelLocation (New-Object System.Drawing.Point(70, 310))
$form.Controls.Add($bannerLabelDBEdition)

# Array of locations for the drop-down list
$db_editions = @("Basic", "Do NOT USE 1", "Do NOT USE 2")

# Create Locations drop down
$dropDownListDBEdition = New-FormDropDownList -DropDownLocation (New-Object System.Drawing.Point(70, 330)) -DropDownItems @($db_editions)

# Define the event handler for the second drop-down list selection change
$dropDownListDBEdition.Add_SelectedIndexChanged({
    $selectedDBEdition = $dropDownListDBEdition.SelectedItem.ToString()
    $global:selectedDBEdition =  $selectedDBEdition
    if ([string]::IsNullOrWhiteSpace($selectedDBEdition)) {
        $bannerLabelDBEdition.Text = "Select an Edition for the database *"
    } 
})

################################################################################
#################### 'Configuration Preview' button ############################ 
################################################################################

# Create button object and properties
$buttonPreviewConfig = New-Object System.Windows.Forms.Button
$buttonPreviewConfig.Text = "Preview Config"
$buttonPreviewConfig.Location = New-Object System.Drawing.Point(70, 360)
$buttonPreviewConfig.Size = New-Object System.Drawing.Size(100, 30)

# Define the event handler for the button click event
$buttonPreviewConfig.Add_Click({
    $serverString = "Server Configuration: "
    $serverString += "`nNew-AzureSqlServer -ResourceGroupName ""$global:selectedResGrp"" -ServerName ""$global:enteredServername"" -Location ""$global:selectedLocation"" -Username ""$global:enteredUserName"" -Password ""$global:enteredPwd"" "
    $serverString += "`n`nDataBase Configuration: "
    $serverString += "`nNew-AzSqlDatabase -ResourceGroupName ""$global:selectedResGrp"" -ServerName ""$global:enteredServername"" -DatabaseName ""$global:enteredSQLDB"" -Edition ""$global:selectedDBEdition"""
    $serverString += "`n`nAre you sure you want to create a new server?"
    $messageBoxButtons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $messageBoxIcon = [System.Windows.Forms.MessageBoxIcon]::Information

    if([string]::IsNullOrEmpty($global:selectedResGrp) -or [string]::IsNullOrEmpty($global:selectedLocation) `
    -or [string]::IsNullOrEmpty($global:enteredServerName) -or [string]::IsNullOrEmpty($global:enteredUserName) `
    -or [string]::IsNullOrEmpty($global:enteredPwd) -or [string]::IsNullOrEmpty($global:enteredSQLDB) `
    -or [string]::IsNullOrEmpty($global:selectedDBEdition)){
        $msg = $null;
        if ([string]::IsNullOrEmpty($global:selectedResGrp)) {
            $msg += "* Resource Group must be selected";
        }
        if ([string]::IsNullOrEmpty($global:selectedLocation)) {
            $msg += "`n* Location must be selected.";
        }
        if ([string]::IsNullOrEmpty($global:enteredServerName)) {
            $msg += "`n* Server Name cannot be empty.";
        }
        if ([string]::IsNullOrEmpty($global:enteredUserName)) {
            $msg += "`n* User Name cannot be empty.";
        }
        if ([string]::IsNullOrEmpty($global:enteredPwd)) {
            $msg += "`n* Password cannot be empty/invalid.";
        }
        if ([string]::IsNullOrEmpty($global:enteredSQLDB)) {
            $msg += "`n* SQL Database Name cannot be empty.";
        }
        if ([string]::IsNullOrEmpty($global:selectedDBEdition)) {
            $msg += "`n* SQL Database Edition must be selected.";
        }
        [System.Windows.Forms.MessageBox]::Show($msg, "Error")
    }else{
        $result = [System.Windows.Forms.MessageBox]::Show($serverString, "Configuration Preview", $messageBoxButtons, $messageBoxIcon)
    }

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        #Disabling inputs when a server creation command invoked.
        $dropDownListResGrps.Enabled = $false;
        $dropDownListLocations.Enabled = $false;
        $inputFieldServerName.Enabled = $false;
        $inputFieldUserName.Enabled = $false;
        $inputFieldPwd.Enabled = $false;
        $buttonPreviewConfig.Enabled = $false;
        $inputFieldSQLDB.Enabled = $false
        $dropDownListDBEdition.Enabled = $false;

        $serverCreating = $true
        $databaseCreating = $true


        # Code for 'Provision a Server' button
        [System.Windows.Forms.MessageBox]::Show("Server is getting created", "Information")
        try {
            $serverCreating = New-AzureSqlServerFunc -ResourceGroupName $global:selectedResGrp -ServerName $global:enteredServername -Location $global:selectedLocation -Username $global:enteredUserName -Password $global:enteredPwd
            # Check if the server was created successfully
            if ($serverCreating) {
                [System.Windows.Forms.MessageBox]::Show("Server created successfully! SQL Database is now getting created..", "Information")
                try {
                    $databaseCreating = New-AzureSqlDataBaseFunc -ResourceGroupName $global:selectedResGrp -ServerName $global:enteredServername -DatabaseName $global:enteredSQLDB -Edition $global:selectedDBEdition
                    # Check if the database was created successfully
                    if ($databaseCreating) {
                        [System.Windows.Forms.MessageBox]::Show("SQL Database created Successfully.", "Information")
                    } else {
                        $inputFieldSQLDB.Enabled = $true
                        $dropDownListDBEdition.Enabled = $true
                        $buttonPreviewConfig.Enabled = $true
                        [System.Windows.Forms.MessageBox]::Show("SQL Database creation failed", "Error")
                    }
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("Error creating SQL Database: $($_.Exception.Message)", "Error")
                }

            } else {
                #Enabling inputs when a server creation failed.
                $dropDownListResGrps.Enabled = $true;
                $dropDownListLocations.Enabled = $true;
                $inputFieldServerName.Enabled = $true;
                $inputFieldUserName.Enabled = $true;
                $inputFieldPwd.Enabled = $true;
                $inputFieldSQLDB.Enabled = $true;
                $dropDownListDBEdition.Enabled = $true;
                $buttonPreviewConfig.Enabled = $true;
                [System.Windows.Forms.MessageBox]::Show("Server creation failed", "Error")
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error creating server: $($_.Exception.Message)", "Error")
        }
    } else {
        # Code for 'Cancel' button
        Write-Host "NO was pressed. Exiting out of preview..."
    }
})


################################################################################
############################# ALL CONTROLS ARE ADDED HERE ######################
################################################################################

# Adding RG banner & drop-down list control to the form
$form.Controls.Add($bannerLabelResgrp)
$form.Controls.Add($dropDownListResGrps)
# Adding locations banner & drop-down list control to the form
$form.Controls.Add($bannerLabelLocation)
$form.Controls.Add($dropDownListLocations)
# Adding server name banner & input control to the form
$form.Controls.Add($bannerLabelServerName)
$form.Controls.Add($inputFieldServerName)
# Adding user name banner & input control to the form
$form.Controls.Add($bannerLabelUserName)
$form.Controls.Add($inputFieldUserName)
# Adding password banner & input control to the form
$form.Controls.Add($bannerLabelPwd)
$form.Controls.Add($inputFieldPwd)
# Adding SQL database banner & input control to the form
$form.Controls.Add($bannerLabelSQLDB)
$form.Controls.Add($inputFieldSQLDB)
# Adding Database Edition banner & drop-down list control to the form
$form.Controls.Add($bannerLabelDBEdition)
$form.Controls.Add($dropDownListDBEdition)
# Adding the button to the form
$form.Controls.Add($buttonPreviewConfig)


################################################################################
############################# FORM DISPLAY INVOKED #############################
################################################################################
$form.ShowDialog()