 <#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AVD Deployment, for Disk Encryption.
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    
      
.EXAMPLE
    Refer - https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
#>

Try {
    $context = Get-AzContext
     If (!$context) {
     Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";
     }
    
     else {

        ######   Declare Variables #######

        $KeyVaultName = '<KeyVaultName>'

        $KVRGname = '<KeyVaultRG>'

        ######   End Declare Variables #######

        Write-Host "Setting required variables..." -BackgroundColor White -ForegroundColor Black

        $Date = Get-Date -Format MM-dd-yyyy_hh-mm_tt

        $VMsFromCSV = Get-Content "VMsToEnableDiskEncryption.txt"

        $PathToLogFile = "EnableDiskEncryption_VMs_Log_$Date.csv"

        $AllVMs = Get-AzVM -Status

        $VMsToStart = @()

        $LogOutput = @()

        $VType ='All'

        $KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $KVRGname

        $diskEncryptionKeyVaultUrl = $KeyVault.VaultUri

        $KeyVaultResourceId = $KeyVault.ResourceId

        $sequenceVersion = [Guid]::NewGuid()

        Write-Host "Getting the list of virtual machines..." -BackgroundColor White -ForegroundColor Black


        foreach ($VMFromCSV in $VMsFromCSV)
        {
            $VMsToStart += $AllVMs | Where-Object {$_.Name -eq $VMFromCSV -and $_.PowerState -eq "VM running"}
        }

        $i = 0

        foreach ($VMToStart in $VMsToStart)
        {
            $i++
            Write-Progress -Activity 'Enabling Disk Encryption for virtual machines...' -CurrentOperation "Virtual machine $($VMsToStart.Name)" -PercentComplete (($i / $VMsToStart.Count) * 100)
            
            Set-AzVMDiskEncryptionExtension -ResourceGroupName $VMToStart.ResourceGroupName -VMName $VMToStart.Name -SequenceVersion $sequenceVersion -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId -VolumeType $VType -SkipVmBackup -Force

            $VMStatusOut = [PSCustomObject][ordered]@{            
                VMName               = $VMToStart.Name
                ResourceGroupName    = $VMToStart.ResourceGroupName
                Message              = "INFORMATION: Virtual machine has been enabled."
                DateTime             = $(Get-Date -Format MM-dd-yyyy_hh-mm-ss_tt)
            }
            $LogOutput += $VMStatusOut
        }

        Write-Host "Exporting data to csv..." -ForegroundColor Black -BackgroundColor White


        $LogOutput | Export-Csv -Path $PathToLogFile -Append -NoTypeInformation
        
        Write-Host "All virtual machines have been processed. Please check $PathToLogFile for more information." -ForegroundColor Black -BackgroundColor White

    }
}

catch {
        Write-Host $_
        Exit;
       }