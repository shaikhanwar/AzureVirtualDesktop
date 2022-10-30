<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, we are installing FSLogix if not already installed.
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    
    The user account deploying AIB should be Global Admin/Owner to perform required changes
  
.EXAMPLE
    Refer - https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
#>

$logFile = "c:\temp\" + (get-date -format 'yyyyMMdd') + '_fslogix_install.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

$LocalWVDpath            = "c:\temp\"
$FSLogixURI              = 'https://aka.ms/fslogix_download'
$FSInstaller             = 'FSLogixAppsSetup.zip'

Invoke-WebRequest -Uri $FSLogixURI -OutFile "$LocalWVDpath$FSInstaller"

Expand-Archive `
    -LiteralPath "C:\temp\$FSInstaller" `
    -DestinationPath "$LocalWVDpath\FSLogix" `
    -Force `
    -Verbose

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-Location -Path "$LocalWVDpath\FSLogix\x64\Release"

$fslogixsetup = "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe"

try {
    foreach ($f in $fslogixsetup) {
        $cmd = "$($f) /install /quiet /norestart"
        start-process -FilePath "cmd " -ArgumentList "/c $cmd" -Wait
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing fslogix: $ErrorMessage"
    
}
