# OS Optimizations for AVD
Write-Host 'AIB Customization: OS Optimizations for AVD'

# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force


$drive = 'C:\'
$FolderName = 'Temp'
New-Item -Path $drive -Name $FolderName -ItemType Directory -ErrorAction SilentlyContinue


invoke-webrequest -uri 'https://github.com/shaikhanwar/AzureVirtualDesktop/blob/c1c1297eb4149d7d99d865ed18403afff885d149/Virtual-Desktop-Optimization-Tool-main.zip' -OutFile 'c:\temp\avdopt.zip'
Expand-Archive 'c:\temp\avdopt.zip' -DestinationPath 'c:\temp' -Force
Set-Location -Path 'C:\temp\Virtual-Desktop-Optimization-Tool-main'


# Sleep for a min
Start-Sleep -Seconds 10
#Running new file

#Write-Host 'Running new AIB Customization script'
.\Windows_VDOT.ps1 -Optimizations AppxPackages -AcceptEula -Verbose

Write-Host 'AIB Customization: Finished OS Optimizations script Windows_VDOT.ps1'