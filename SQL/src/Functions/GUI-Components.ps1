function Add-CheckBox {
    param (
        [string]$Text,
        [int]$X,
        [int]$Y,
        [System.Windows.Forms.Form]$Form
    )

    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $Text
    $checkbox.Location = New-Object System.Drawing.Point($X, $Y)
    $checkbox.AutoSize = $true
    $Form.Controls.Add($checkbox)

    return $checkbox
}

function Disable-CheckedCheckboxes {
    param (
        [System.Windows.Forms.CheckBox[]]$CheckBoxes
    )

    foreach ($checkbox in $checkboxes) {
        if ($checkbox.Checked) {
            $checkbox.Enabled = $false
        }
    }
}

function Add-Button {
    param (
        [string]$Text,
        [int]$X,
        [int]$Y,
        [System.Windows.Forms.Form]$Form
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $Form.Controls.Add($button)
    return $button
}

function Add-Label {
    param (
        [string]$Text,
        [int]$X,
        [int]$Y,
        [System.Windows.Forms.Form]$Form
    )

    $label = New-Object System.Windows.Forms.Label
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Text = $Text

    $Form.Controls.Add($label)

    return $label
}

function Add-TextBox {
    param (
        [string]$Label,
        [int]$X,
        [int]$Y,
        [int]$Width = 150,
        [System.Windows.Forms.Form]$Form
    )

    $label = Add-Label -Text $Label -X $X -Y $Y -Form $Form

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point($X, ($Y + 20))
    $textbox.Width = $Width

    $Form.Controls.Add($textbox)

    return $textbox, $label
}






