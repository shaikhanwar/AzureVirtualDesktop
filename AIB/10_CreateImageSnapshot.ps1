<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, we are generating an Image from the Master VM.
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    
    The user account deploying AIB should be Global Admin/Owner to perform required changes
    The script creates a snapshot and provisions a temp VM to generate an Image by doing this we are preserving the Master VM for future use, 
    optionally this script can perform cleanup if the $delSnap is set to $true.

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

    # Specify Subscription and Location
    $SubscriptionID = "<SubscriptionID>"
    $Location = "<Location>"

    # Specify Source VM Information
    $SourceVmName = "<SourceVmName>"
    $SourceVmRG = "<SourceVMResourceGroup>"

    # Create Temp RG to Capture ****
    $capVmRg = "<TempRG>"

    # Specify Azure Computer Gallery Details
    $galName = "<GalleryName>"
    $galRg =  "<GalleryRG>"
    $galDeploy = "True"
    $delSnap = $true

    $VNETName = "<VNetName>"
    $SubnetName = "<SubnetName>"
    $VNetRG = "<VNetResourceGroup"

    ######  End Declare Variables #######

    # Sysrep URI
    $cseURI = 'https://raw.githubusercontent.com/shaikhanwar/AzureVirtualDesktop/main/AIB/SysprepCSE.ps1'

    # Create Resource Group to Capture AV
    New-AzResourceGroup -Name $capVmRg -Location $Location 

    # Getting Subnet ID
    $SubnetId = "/subscriptions/$SubscriptionID/resourceGroups/$VNetRG/providers/Microsoft.Network/virtualNetworks/$VNETName/subnets/$SubnetName"

    #Set the date, used as unique ID for artifacts and image version
    $date = (get-date -Format yyyyMMddHHmm)

    #Set the image name, modify as needed
    $imageName = ($SourceVmName + 'Image' + $date)

    #Set the image version (Name)
    #Used if adding the image to an Azure Compute Gallery
    #Format is 0.yyyyMM.ddHHmm date format for the version to keep unique and increment each new image version
    $imageVersion = '0.' + $date.Substring(0, 6) + '.' + $date.Substring(6, 6)

    # Disabling breaking change warning message
    Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true

    # Setting the location, based on the reference computer resource group location
    $location = (Get-AzResourceGroup -Name $SourceVmRg).Location

    # Getting Gallery Information
    $Gallery = Get-AzGalleryImageDefinition -ResourceGroupName $galRg -GalleryName $galName

    # Create Snapshot of reference VM
    try {
        Write-Host "Creating a snapshot of $SourceVmName"
        $vm = Get-AzVM -ErrorAction Stop -ResourceGroupName $SourceVmRg -Name $SourceVmName
        $snapshotConfig = New-AzSnapshotConfig -ErrorAction Stop -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $vm.Location -CreateOption copy -SkuName Standard_LRS
        $snapshot = New-AzSnapshot -ErrorAction Stop -Snapshot $snapshotConfig -SnapshotName "$SourceVmRg$date" -ResourceGroupName $capVmRg
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error creating snapshot from reference computer ' + $ErrorMessage)
        Break
    }

    Try {
        $osDiskConfig = @{
            ErrorAction      = 'Stop'
            Location         = $location
            CreateOption     = 'copy'
            SourceResourceID = $snapshot.Id
        }
        write-host "creating the OS disk from the snapshot"
        $osDisk = New-AzDisk -ErrorAction Stop -DiskName 'TempOSDisk' -ResourceGroupName $capVmRg -disk (New-AzDiskConfig @osDiskConfig) -WarningAction silentlyContinue
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error creating the managed disk ' + $ErrorMessage)
        Break
    }

    # Creating Temp NSG
    Try {
        $nsgRuleConfig = @{
            Name                     = 'myRdpRule'
            ErrorAction              = 'Stop'
            Description              = 'Allow RDP'
            Access                   = 'allow'  
            Protocol                 = 'Tcp'
            Direction                = 'Inbound'
            Priority                 = '110'
            SourceAddressPrefix      = 'Internet'
            SourcePortRange          = '*'
            DestinationAddressPrefix = '*'
            DestinationPortRange     = '3389'
        }
        write-host "Creating the NSG"
        $rdpRule = New-AzNetworkSecurityRuleConfig @nsgRuleConfig
        $nsg = New-AzNetworkSecurityGroup -ErrorAction Stop -ResourceGroupName $capVmRg -Location $location -Name 'tempNSG' -SecurityRules $rdpRule
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error creating the NSG ' + $ErrorMessage)
        Break
    }

    # Creating NIC
    Try {
        $nicConfig = @{
            ErrorAction            = 'Stop'
            Name                   = 'tempNic'
            ResourceGroupName      = $capVmRg
            Location               = $location
            SubnetId               = $SubnetId
            NetworkSecurityGroupId = $nsg.Id
        }
        Write-Host "Creating the NIC"
        $nic = New-AzNetworkInterface @nicConfig
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error creating the NIC ' + $ErrorMessage)
        Break
    }
    # Create and start the VM
    Try {
        Write-Host "Creating the temporary capture VM, this will take a couple minutes"
        $capVmName = ('tempVM' + $date) 
        $CapVmConfig = New-AzVMConfig -ErrorAction Stop -VMName $CapVmName -VMSize $vm.HardwareProfile.VmSize
        $capVm = Add-AzVMNetworkInterface -ErrorAction Stop -vm $CapVmConfig -id $nic.Id
        $capVm = Set-AzVMOSDisk -vm $CapVm -ManagedDiskId $osDisk.id -StorageAccountType Standard_LRS -DiskSizeInGB $osDisk.DiskSizeGB -CreateOption Attach -Windows
        $capVM = Set-AzVMBootDiagnostic -vm $CapVm -disable
        $capVm = new-azVM -ResourceGroupName $capVmRg -Location $location -vm $capVm -DisableBginfoExtension -WarningAction silentlyContinue
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error creating the VM ' + $ErrorMessage)
        Break
    }

    $displayStatus = ""

    $count = 0

    while ($displayStatus -notlike "VM running") { 
        Write-Host "Waiting for the VM display status to change to VM running"
        $displayStatus = (get-azvm -Name $capVmName -ResourceGroupName $capVmRg -Status).Statuses[1].DisplayStatus
        write-output "starting 30 second sleep"
        start-sleep -Seconds 30
        $count += 1
        if ($count -gt 7) { 
            Write-Error "five minute wait for VM to start ended, canceling script"
            Exit
        }
    }
    # Run Sysprep from a Custom Script Extension 
    try {
        $cseSettings = @{
            ErrorAction       = 'Stop'
            FileUri           = $cseURI 
            ResourceGroupName = $capVmRg
            VMName            = $CapVmName 
            Name              = "Sysprep" 
            location          = $location 
            Run               = './SysprepCSE.ps1'
        }
        Write-Host "Running the Sysprep custom script extension"
        Invoke-Command -ScriptBlock {Set-AzVMCustomScriptExtension @cseSettings | Out-Null}

    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error running the Sysprep Custom Script Extension ' + $ErrorMessage)
        Break
    }

    $displayStatus = ""

    $count = 0

    Try {
        while ($displayStatus -notlike "VM stopped") {
            Write-Host "Waiting for the VM display status to change to VM stopped"
            $displayStatus = (get-azvm -ErrorAction Stop -Name $capVmName -ResourceGroupName $capVmRg -Status).Statuses[1].DisplayStatus
            write-output "starting 15 second sleep"
            start-sleep -Seconds 15
            $count += 1
            if ($count -gt 11) {
                Write-Error "Three minute wait for VM to stop ended, canceling script.  Verify no updates are required on the source"
                Exit 
            }
        }
        Write-Host "Deallocating the VM and setting to Generalized"
        Stop-AzVM -ErrorAction Stop -ResourceGroupName $capVmRg -Name $capVmName -Force | Out-Null
        Set-AzVM -ErrorAction Stop -ResourceGroupName $capVmRg -Name $capVmName -Generalized | Out-Null
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error deallocating the VM ' + $ErrorMessage)
        Break
    }

    Try {
        Write-Host "Capturing the VM image"
        $capVM = Get-AzVM -ErrorAction Stop -Name $capVmName -ResourceGroupName $capVmRg
        $vmGen = (Get-AzVM -ErrorAction Stop -Name $capVmName -ResourceGroupName $capVmRg -Status).HyperVGeneration
        $image = New-AzImageConfig -ErrorAction Stop -Location $location -SourceVirtualMachineId $capVm.Id -HyperVGeneration $vmGen

        if ($galDeploy -eq $true) {
            Write-Host "Azure Compute Gallery used, saving image to the capture VM Resource Group"
            $image = New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $capVmRg
        }

        elseif ($galDeploy -eq $false) {
            Write-Host "Azure Compute Gallery not used, saving image to the reference VM Resource Group"
            New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $SourceVmRg | Out-Null
        }
        else {
            Write-Error 'Please set galDeploy to $true or $false'
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error creating the image ' + $ErrorMessage)
        Break
    }

    #Add image to the Azure Compute Gallery if that option was selected
    Try {
        if ($galDeploy -eq $true) {
            Write-Host 'Adding image to the Azure Compute Gallery, this can take a few minutes'
            $imageSettings = @{
                ErrorAction                = 'Stop'
                ResourceGroupName          = $Gallery.ResourceGroupName
                GalleryName                = $galName
                GalleryImageDefinitionName = $Gallery.Name
                Name                       = $imageVersion
                Location                   = $gallery.Location
                SourceImageId              = $image.Id
            }
            $GalImageVer = New-AzGalleryImageVersion @imageSettings
            Write-Host "Image version $($GalImageVer.Name) added to the image definition"
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error adding the image to the Azure Compute Gallery ' + $ErrorMessage)
        Break
    }

    #region Remove the capture computer RG, this will delete the temp RG created

    Try {
    if ($delSnap -eq $true){
    
        Write-Host "Removing the capture Resource Group $($capVmRg)"
        Remove-AzResourceGroup -ErrorAction Stop -Name $capVmRg -Force | Out-Null
    }
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error removing resource group ' + $ErrorMessage)
        Break
        }
    }
}

Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] 
    {
        Write-Host $_     
        Exit;
    }
