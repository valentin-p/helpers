#You cannot download more than 50 MB or upload large Files using Web Client in Windows
#https://support.microsoft.com/en-us/help/2668751/you-cannot-download-more-than-50-mb-or-upload-large-files-when-the-upl#letmefixitmyselfalways

#Run un Powerhsell in Admin
$pathParam = "HKLM:\SYSTEM\CurrentControlSet\Services\WebClient\Parameters" 
$limitBytes = (Get-ItemProperty -Path $pathParam -Name FileSizeLimitInBytes).FileSizeLimitInBytes
#Check the current limit
$limitBytes

if($limitBytes -eq 50000000){
    # Increase to 1 GB = 1000000000
    Set-ItemProperty -Path $pathParam -Name FileSizeLimitInBytes -Value 1000000000
}
