function Save-OutputToFile($path, $content) {
    $content | Out-File -FilePath $path
}