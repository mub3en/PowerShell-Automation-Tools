# functions.psm1

#export Create Label Module
function New-FormLabel {
    param (
        [string]$LabelText,
        [System.Drawing.Point]$LabelLocation
    )

    # Create a label for the banner
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $LabelText
    $label.Location = $LabelLocation
    $label.Size = New-Object System.Drawing.Size(200, 20)

    return $label
}

#export DropDown List Module
function New-FormDropDownList {
    param (
        [System.Drawing.Point]$DropDownLocation,
        [string[]]$DropDownItems
    )

    # Create a drop-down list control
    $dropDownList = New-Object System.Windows.Forms.ComboBox
    $dropDownList.Location = $DropDownLocation
    $dropDownList.Size = New-Object System.Drawing.Size(200, 20)
    $dropDownList.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    # Add items to the drop-down list
    $dropDownList.Items.AddRange($DropDownItems)

    return $dropDownList
}

Export-ModuleMember -Function 'New-FormLabel', 'New-FormDropDownList'