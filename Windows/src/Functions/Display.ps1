
function DisplayTable($title, $data) {
    Write-Host
    Write-Host $title
    Write-Host ('-' * $title.Length)
    Write-Host
    $data | Format-Table -AutoSize
}

