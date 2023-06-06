# functions.psm1

#export Create Label Module
function New-FormLabel {
    param (
        [string]$LabelText = '',
        [System.Drawing.Point]$LabelLocation = [System.Drawing.Point]::Empty,
        [System.Drawing.Size]$LabelSize = [System.Drawing.Size]::Empty,
        [System.Drawing.Color]$ForeColor = [System.Drawing.Color]::Black,
        [bool]$FontBold = $true
    )

    if ($LabelLocation -eq [System.Drawing.Point]::Empty) {
        $LabelLocation = New-Object System.Drawing.Point(10, 10)
    }

    if ($LabelSize -eq [System.Drawing.Size]::Empty) {
        $LabelSize = New-Object System.Drawing.Size(200, 20)
    }

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $LabelText
    $label.Location = $LabelLocation
    $label.Size = $LabelSize
    $label.ForeColor = $ForeColor

    if ($FontBold) {
        $label.Font = New-Object System.Drawing.Font($label.Font.Name, $label.Font.Size, [System.Drawing.FontStyle]::Bold)
    }

    return $label
}

# function New-FormLabel {
#     param (
#         [string]$LabelText = '',
#         [System.Drawing.Point]$LabelLocation = [System.Drawing.Point]::Empty,
#         [System.Drawing.Size]$LabelSize = [System.Drawing.Size]::Empty,
#         [System.Drawing.Color]$ForeColor = [System.Drawing.Color]::Black,
#         [bool]$FontBold = $true
#     )

#     if ($LabelLocation -eq [System.Drawing.Point]::Empty) {
#         $LabelLocation = New-Object System.Drawing.Point(10, 10)
#     }

#     if ($LabelSize -eq [System.Drawing.Size]::Empty) {
#         $LabelSize = New-Object System.Drawing.Size(200, 20)
#     }

#     $labelProps = @{
#         Text = $LabelText
#         Location = $LabelLocation
#         Size = $LabelSize
#         ForeColor = $ForeColor
#         Font = if ($FontBold) { New-Object System.Drawing.Font($label.Font, [System.Drawing.FontStyle]::Bold) } else { $label.Font }
#     }

#     $label = New-Object System.Windows.Forms.Label
#     $labelProps.GetEnumerator() | ForEach-Object { $label.SetPropertyValue($_.Key, $_.Value) }

#     return $label
# }

#export DropDown List Module
function New-FormDropDownList {
    param (
        [System.Drawing.Point]$DropDownLocation = [System.Drawing.Point]::Empty,
        [string[]]$DropDownItems = @(),
        [System.Drawing.Size]$DropDownSize = [System.Drawing.Size]::Empty
    )

    $dropDownList = New-Object System.Windows.Forms.ComboBox

    if ($DropDownLocation -ne [System.Drawing.Point]::Empty) {
        $dropDownList.Location = $DropDownLocation
    }

    if ($DropDownSize -ne [System.Drawing.Size]::Empty) {
        $dropDownList.Size = $DropDownSize
    }
    else {
        $dropDownList.Size = New-Object System.Drawing.Size(200, 20)
    }

    $dropDownList.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    if ($DropDownItems) {
        $dropDownList.Items.AddRange($DropDownItems)
    }

    return $dropDownList
}

#export Text Input Module
function New-TextInputField {
    param (
        [System.Drawing.Point]$TextInputLocation = [System.Drawing.Point]::Empty,
        [System.Drawing.Size]$TextInputSize = [System.Drawing.Size]::Empty
        # ,[bool]$ValidationRequired = $false
        # ,[string]$ValidationPattern = ''
    )

    $textInputField = New-Object System.Windows.Forms.TextBox

    # if ($ValidationRequired) {
    #     $textInputField.add_TextChanged({
    #         if ([string]::IsNullOrWhiteSpace($textInputField.Text)) {
    #             $textInputField.ForeColor = [System.Drawing.SystemColors.Window]
    #             $textInputField.Tag = $false
    #         }
    #         elseif ($textInputField.Text -cmatch $ValidationPattern) {
    #             $textInputField.ForeColor = [System.Drawing.SystemColors.Window]
    #             $textInputField.Tag = $true
    #         }
    #         else {
    #             $textInputField.ForeColor = [System.Drawing.Color]::Red
    #             $textInputField.Tag = $false
    #         }
    #     })
    # }

    if ($TextInputLocation -ne [System.Drawing.Point]::Empty) {
        $textInputField.Location = $TextInputLocation
    }

    if ($TextInputSize -ne [System.Drawing.Size]::Empty) {
        $textInputField.Size = $TextInputSize
    }
    else {
        $textInputField.Size = New-Object System.Drawing.Size(200, 20)
    }

    return $textInputField
}

function New-AzureSqlServerFunc {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$Location,
        [string]$Username,
        [string]$Password
    )

    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, (ConvertTo-SecureString -String $Password -AsPlainText -Force)
    
    New-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Location $Location -SqlAdministratorCredentials $Credential
}

function New-AzureSqlDataBaseFunc {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$DataBaseName,
        [string]$DBEdition
    )
    
    New-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DataBaseName -Edition $DBEdition
}



Export-ModuleMember -Function 'New-FormLabel', 'New-FormDropDownList', 'New-TextInputField', 'New-AzureSqlServerFunc', 'New-AzureSqlDataBaseFunc'