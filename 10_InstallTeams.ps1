 # set regKey
 write-host 'AIB Customization: Set required regKey'
 New-Item -Path HKLM:\SOFTWARE\Microsoft -Name "Teams" 
 New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Teams -Name "IsWVDEnvironment" -Type "Dword" -Value "1"
 write-host 'AIB Customization: Finished Set required regKey'
 

$appName = 'teams'
$drive = 'C:\'
New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath              = $drive + '\' + $appName
$TeamsURI               = 'https://aka.ms/fslogix_download'
$TeamsInstaller         = 'FSLogixAppsSetup.zip'


Invoke-WebRequest -Uri $TeamsURI -OutFile "$LocalPath$TeamsInstaller"

Expand-Archive `
    -LiteralPath "C:\teams\$TeamsInstaller" `
    -DestinationPath "$LocalPath\TeamsSetup" `
    -Force `
    -Verbose


    try {
        set-Location $LocalPath
        $visCplusURLexe = 'vc_redist.x64.exe'
        $outputPath = $LocalPath + '\' + $visCplusURLexe
        write-host 'AIB Customization: Starting Install the latest Microsoft Visual C++ Redistributable'
        Start-Process -FilePath $outputPath -Args "/install /quiet /norestart /log vcdist.log" -Wait
        write-host 'AIB Customization: Finished Install the latest Microsoft Visual C++ Redistributable'
        
    }
    catch {
        $ErrorMessage = $_.Exception.message
        write-log "Error installing vcredist: $ErrorMessage"
    }

    try {
        set-Location $LocalPath
        $webSocketsInstallerMsi = 'webSocketSvc.msi'
        $outputPath = $LocalPath + '\' + $webSocketsInstallerMsi
        write-host 'AIB Customization: Starting Install the Web Scoket'
        Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log webSocket.log" -Wait
        write-host 'AIB Customization: Finished Install the Teams WebSocket Service'
        
        
    }
    catch {
        $ErrorMessage = $_.Exception.message
        write-log "Error installing WebSocket: $ErrorMessage"
    }

    try {
        set-Location $LocalPath
        $teamsMsi = 'Teams_windows_x64.msi'
        $outputPath = $LocalPath + '\' + $teamsMsi
        write-host 'AIB Customization: Starting Teams Install'
        Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log teams.log ALLUSER=1 ALLUSERS=1" -Wait
        write-host 'AIB Customization: Finished Install MS Teams' 
        
    }
    catch {
        $ErrorMessage = $_.Exception.message
        write-log "Error installing Teams: $ErrorMessage"
    }

