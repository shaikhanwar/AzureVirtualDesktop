<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool

.DESCRIPTION
    This snippet is part of AIB Deployment, to create Managed Identity for AIB.
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    The Virtual Desktop Optimization Tool (VDOT) is a set of mostly text-based tools that apply settings to a Windows operating system, 
    intended to improve performance. The performance gains are in overall startup time, first logon time, subsequent logon time, 
    and usability during a user-session.

    The user account deploying AIB should be Global Admin/Owner to perform required changes

.EXAMPLE
    Refer for more information - https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
#>


# OS Optimizations for AVD
Write-Host 'AIB Customization: OS Optimizations for AVD'

# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force


$drive = 'C:\'
$FolderName = 'Temp'
New-Item -Path $drive -Name $FolderName -ItemType Directory -ErrorAction SilentlyContinue


invoke-webrequest -uri 'https://github.com/shaikhanwar/AzureVirtualDesktop/blob/main/AIB/Virtual-Desktop-Optimization-Tool-main.zip?raw=true' -OutFile 'c:\temp\avdopt.zip'
Expand-Archive 'c:\temp\avdopt.zip' -DestinationPath 'c:\temp' -Force
Set-Location -Path 'C:\temp\Virtual-Desktop-Optimization-Tool-main'


# Sleep for a min
Start-Sleep -Seconds 10
#Running new file

#Write-Host 'Running new AIB Customization script'
.\Windows_VDOT.ps1 -Optimizations AppxPackages -AcceptEula -Verbose

Write-Host 'AIB Customization: Finished OS Optimizations script Windows_VDOT.ps1'