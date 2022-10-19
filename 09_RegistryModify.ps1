
$logFile = "c:\temp\" + (get-date -format 'yyyyMMdd') + '_regkey_modify.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

##########################################
#    Hide drives A, D, E                 #
##########################################

$name = "NoDrives"
$value = "25" #1+8+16=25
# Add Registry value
try {

    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
        -Name $name `
        -Value $value `
        -PropertyType DWORD `
        -Force `
        -Confirm:$false


    if ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer").PSObject.Properties.Name -contains $name) {
        Write-log "Added time zone redirection registry key"
        Write-Output "***** Hiding drives"
    }
    else {
        write-log "Error locating the Teams registry key"
        Write-Output "***** Error locating the NoDrives regkey"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding hide drive registry KEY: $ErrorMessage"
    Write-Output "***** Error adding hide drive registry KEY: $ErrorMessage"
}

##########################################
#    Sessions Control                    #
##########################################
$Name = "MaxDisconnectionTime"
# Add Registry value
try {

    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
        -Name $Name `
        -Value "1800000" `
        -PropertyType DWORD `
        -Force `
        -Confirm:$false


    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-log "Added Max Disconnected Time registry key"
        Write-Output "Added Max Disconnected Time registry key"
    }
    else {
        write-log "Error locating the Time Disconnect registry key"
        Write-Output "***** Error locating the Time Disconnect registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding Time Disconnect registry key: $ErrorMessage"
    Write-Output "***** Error adding Time Disconnect registry key: $ErrorMessage"
}


$Name = "RemoteAppLogoffTimeLimit"
# Add Registry value
try {

    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
        -Name $Name `
        -Value "1800000" `
        -PropertyType DWORD `
        -Force `
        -Confirm:$false


    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-log "Added Max Remote App LogOff Time registry key"
        Write-Output "Added Max Remote App LogOff Time registry key"
    }
    else {
        write-log "Error locating the Remote App LogOff Time registry key"
        Write-Output "***** Error locating the Remote App LogOff Time registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding Remote App LogOff Time registry key: $ErrorMessage"
    Write-Output "***** Error adding Remote App LogOff Time registry key: $ErrorMessage"
}

$Name = "MaxIdleTime"
# Add Registry value
try {

    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
        -Name $Name `
        -Value "7200000" `
        -PropertyType DWORD `
        -Force `
        -Confirm:$false

    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-log "Added Max Idle Time registry key"
        Write-Output "Added Max Idle Time registry key"
    }
    else {
        write-log "Error locating the Max Idle Time registry key"
        Write-Output "***** Error locating the Max Idle Time registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding Max Idle Time registry key: $ErrorMessage"
    Write-Output "***** Error adding Max Idle Time registry key: $ErrorMessage"
}

##########################################
#    Region Time Zone Redirection        #
##########################################

$Name = "fEnableTimeZoneRedirection"
$value = "1"
# Add Registry value
try {
    New-ItemProperty -ErrorAction Stop -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name $name -Value $value -PropertyType DWORD -Force
    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-log "Added time zone redirection registry key"
        Write-Output "***** Added time zone redirection registry key"
    }
    else {
        write-log "Error locating the Time registry key"
        Write-Output "***** Error locating the Time registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding Time registry KEY: $ErrorMessage"
    Write-Output "***** Error adding Time registry KEY: $ErrorMessage"
}


### Setting the RDP Shortpath.
Write-Host 'Configuring RDP ShortPath'

$WinstationsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'

if (Test-Path $WinstationsKey) {
    New-ItemProperty -Path $WinstationsKey -Name 'fUseUdpPortRedirector' -ErrorAction:SilentlyContinue -PropertyType:dword -Value 1 -Force
    New-ItemProperty -Path $WinstationsKey -Name 'UdpPortNumber' -ErrorAction:SilentlyContinue -PropertyType:dword -Value 3390 -Force
}

Write-Host 'Settin up the Windows Firewall Rue for RDP ShortPath'
New-NetFirewallRule -DisplayName 'Remote Desktop - Shortpath (UDP-In)' -Action Allow -Description 'Inbound rule for the Remote Desktop service to allow RDP traffic. [UDP 3390]' -Group '@FirewallAPI.dll,-28752' -Name 'RemoteDesktop-UserMode-In-Shortpath-UDP' -PolicyStore PersistentStore -Profile Domain, Private -Service TermService -Protocol udp -LocalPort 3390 -Program '%SystemRoot%\system32\svchost.exe' -Enabled:True

