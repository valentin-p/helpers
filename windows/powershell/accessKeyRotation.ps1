# replace the old and new key and secrets, run in the C:/git folder with a powershell shell.
$oldAccessKey = ""
$oldSecretKey = ""

$newAccessKey = ""
$newSecretKey = ""

$awsKey = "AWSAccessKey`" value=`""+$oldAccessKey 
$filesWithValue = Get-ChildItem -Recurse -Exclude bin,obj -Include app.d.config,web.d.config | Select-String $awsKey -List | Select Path
foreach ($file in $filesWithValue)
{
    $path = $file.Path
    $content = [IO.File]::ReadAllText($path)
    $newKeyContent = $content -replace $oldAccessKey,$newAccessKey
    $finalContent = $newKeyContent -replace $oldSecretKey,$newSecretKey
    out-file -InputObject $finalContent -Encoding ASCII -FilePath $path
    Write-Host "$path"
}
