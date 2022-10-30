## Abstracts

# **Using PowerShell to Create a Windows Virtual Desktop Custom Image using Azure VM Image Builder**

---
## Workshop

In this workshop, you will automate using the Azure VM Image Builder, and distibute to the Azure Shared Image Gallery, where you can replicate regions, control the scale, and share inside and outside your organizations. To simplify deploying an AIB configuration template with PowerShell CLI.

This walk through is intended to be a copy and paste exercise however you may have to specify key variable values pertaining to your environment, and will provide you with a custom Windows 11 22H2 Multi Session Server image, showing you how you can easily create a custom image.

---
## Step 1: Set up Login and context
In this step, we will be setting up Login and Subscription Context
```powershell
Try {
# Import Module
Import-Module Az.Accounts

# Connect Azure
Connect-AzAccount

Write-Host "Connecting to Azure Account" `n

# Specify Subscription ID
$SubscriptionID = "<SubscriptionID>"

# Set Az Context
Set-AzContext -Subscription $SubscriptionID -ErrorAction Stop

# Define Location
$Location = "<Location>"

}

catch {
     Write-Host $_
     Exit;
    }

```
---
## Step 2: Register Providers for Azure Image Builder

In this step, we are trying to register required providers for Azure Image Builder, it does few minutes to complete. You need to ensure the providers are registered before proceeding further.

```powershell
Try {
    $context = Get-AzContext

    If (!$context) {
        Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";
        }
 else {

    Write-Host "You are connected. Continuing ...."

     # Register for Azure Virtual Desktop
     Register-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization 

     # Register for Azure Image Builder
     Register-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

     # You may have to wait until RegistrationState is set to 'Registered'
     Get-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

     # Verify RegistrationState is set to 'Registered'. by running 1 at a time
     # Get-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization
     # Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
     # Get-AzResourceProvider -ProviderNamespace Microsoft.Storage 
     # Get-AzResourceProvider -ProviderNamespace Microsoft.Compute
     # Get-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

     # If they you do not see registered, run the commented out code below.
     ## Register-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization
     ## Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
     ## Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
     ## Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
     ## Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

    }
}
Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] 
    {
        Write-Host $_     
        Exit;
    }
```
## Step 3: Create Resource Groups

Here we are creating Resouce Groups to place AIB / AVD Objects. In addition to this we are also creating a Temporary Resource Group to create snapshots without destroying the Master Image.

Note - You need to store Master Image in a seperate Resource Group for future use. You can use AIB Resource Group to store the Master Image.

```powershell
Try {
    $context = Get-AzContext

    If (!$context) {
            Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";
        }
    
    else {
        ######   Declare Variables #######
        
        # Specify Resource Group for AIB
        $AIBResourceGroup = "<AIBResourceGroup>"
        
        # Specify Resource Group for AVd
        $AVDResourceGroup = "<AVDResourceGroup"

        # Specify Location
        $Location = "<Location>"

        # Temp Resource Group for Image
        $TempRG = "<TempRG>"

        ######   End Declare Variables #######

        # Create Resource Group for AIB
        New-AzResourceGroup -Name $AIBResourceGroup -Location $Location 

        # Create Resource Group for AVD
        New-AzResourceGroup -Name $AVDResourceGroup -Location $Location

         # Create Temp Resource Group for Image
         New-AzResourceGroup -Name $TempRG -Location $Location 
    }
}

Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] 
{   
    Write-Host $_
    Exit;   
}
```
---
## Step 4: Create Managed Identity

In this step we are creating Managed Identity for AIB.

```powershell
Try {
    $context = Get-AzContext
    If (!$context) {
            Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";
        }
    
    else {
        ######   Declare Variables #######

       # Define Variables
        $AIBResourceGroup = "<AIBResourceGroup>"

        # Define Variables
        $Location = "<Location>"
        
        ######   End Declare Variables #######

        # Setup Unique name for AIB Image Defination
        $timeInt=$(get-date -UFormat "%s")

        # If you get any error creating the $timeInt variable
        #$timeInt=$((get-date -UFormat "%s").Split('.')[0])

        # Managed Identity Name - Unique accross Azure
        $ManagedIdentityName  =  "aibIdentity"+$timeInt

        # Addind Az Modules for AzUserAssignedIdentity & AIB
        'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}

        # Create Managed Identity
        New-AzUserAssignedIdentity -ResourceGroupName $AIBResourceGroup  -Name $ManagedIdentityName -Location $Location

        # Get Managed Identity ID
        $idenityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $AIBResourceGroup -Name $ManagedIdentityName).Id

        # Get Managed Identity Principal ID
        $idenityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $AIBResourceGroup -Name $ManagedIdentityName).PrincipalId
    }
}
catch {
    Write-Host $_
    Exit;
   }
```
---
## Step 5: Create Custom Role for AIB and Grant Managed Identity Permission on Resource Group

Here we are creating a Custom Role for AIB and Granting it to the Managed Identity created in previous step with scope as Resource Group.

```powershell
Try {
    $context = Get-AzContext
    If (!$context) {
            Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";
        }
else {

    ######   Declare Variables #######
    # Specify Resource Group Name
    $AIBResourceGroup = "<AIBResourceGroup>"

    # Specify Subscription ID
    $SubscriptionID = "<SubscriptionID>"

    #Specify Managed Identity Name
    $ManagedIdentityName = "<ManageIdentityName>"

    ######   End Declare Variables #######

    # AIB Image Defination Name - Unique"
    $AIBCustomRoleName = "Azure Image Builder Image Custom Role"

    $AIBGitCreationUrl = "https://raw.githubusercontent.com/shaikhanwar/AzureVirtualDesktop/main/AIB/AIBPermission.json"

    $AIBCreationPath = "AIBPermission.json"

    # download config
    Invoke-WebRequest -Uri $AIBGitCreationUrl -OutFile $AIBCreationPath -UseBasicParsing

    ((Get-Content -path $AIBCreationPath -Raw) -replace '<subscriptionID>',$SubscriptionID) | Set-Content -Path $AIBCreationPath
    ((Get-Content -path $AIBCreationPath -Raw) -replace '<rgName>', $AIBResourceGroup) | Set-Content -Path $AIBCreationPath
    ((Get-Content -path $AIBCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $AIBCustomRoleName) | Set-Content -Path $AIBCreationPath

    # create role definition
    New-AzRoleDefinition -InputFile  ./AIBPermission.json

    #Get PrincipalId for ManagedIdentity
    $idenityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $AIBResourceGroup -Name $ManagedIdentityName).PrincipalId

    # Grant role definition to image builder service principal
    New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $AIBCustomRoleName -Scope "/subscriptions/$SubscriptionID/resourceGroups/$AIBResourceGroup"

    ### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
    ##https://docs.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
        }
    }
    catch {
        Write-Host $_
        Exit;
        }
```
---
## Step 6: Create Custom Role for AIB and Grant Managed Identity Permission on VNet

In this step we are again creating a Custom Role for AIB and Granting it to the Managed Identity created in previous step to read VNet and Subnet Configuration if stored in different Resource Group.

```powershell
Try {
    $context = Get-AzContext
    If (!$context) {
            Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";
        }

else {
# Specify Resource Group Name
$VNetResourceGroup = "<VNetResourceGroup>"

# Specify Subscription ID
$SubscriptionID = "<SubscriptionID>"

# Specify Resource Group Name
$AIBResourceGroup = "<AIBResourceGroup>"

#Specify Managed Identity Name
$ManagedIdentityName = "<ManagedIdentityName>"

# AIB Image Defination Name - Unique"
$AIBCustomRoleName = "Azure Image Builder Image Network Custom Role"

$AIBGitCreationUrl = "https://raw.githubusercontent.com/shaikhanwar/AzureVirtualDesktop/main/AIB/VNetPermission..json"

$AIBCreationPath = "VNetPermission..json"

# download config
Invoke-WebRequest -Uri $AIBGitCreationUrl -OutFile $AIBCreationPath -UseBasicParsing

((Get-Content -path $AIBCreationPath -Raw) -replace '<subscriptionID>',$SubscriptionID) | Set-Content -Path $AIBCreationPath
((Get-Content -path $AIBCreationPath -Raw) -replace '<rgName>', $VNetResourceGroup) | Set-Content -Path $AIBCreationPath
((Get-Content -path $AIBCreationPath -Raw) -replace 'Azure Image Builder Image Custom Role', $AIBCustomRoleName) | Set-Content -Path $AIBCreationPath

# create role definition
New-AzRoleDefinition -InputFile  ./VNetPermission..json

#Get PrincipalId for ManagedIdentity
$idenityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $AIBResourceGroup -Name $ManagedIdentityName).PrincipalId

# Grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $AIBCustomRoleName -Scope "/subscriptions/$SubscriptionID/resourceGroups/$VNetResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
##https://docs.microsoft.com/en-us/azure/role-based-access-control/troubleshooting

    }
}
catch {
    Write-Host $_
    Exit;
    }
```
---
## Step 7: Create Shared Image Gallery

Creating Shared Image Gallery, You can define Gallery Properties as you seem relevant.

```powershell
Try {
    $context = Get-AzContext
    If (!$context) {
        Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";
    }
    else {
        ######   Declare Variables #######
        # Specify the resource Group
        $AIBResourceGroup = "<AIBResourceGroup>"
        
        # Define Location
        $location = "<Location>"       
        
        # Define Gallery Properties
        $sigGalleryName = "<GalleryName>"
        $publisherName = "GreatPublisher"
        $offerName = "GreatOffer"
        $skuName = "GreatSku"
        $description = "My gallery"
        $generation = "V2"
        $IsAcceleratedNetworkSupported = @{Name='IsAcceleratedNetworkSupported';Value='False'}
        $features = @($IsAcceleratedNetworkSupported)

        # Specify the Shared Image Defination Name - Only Alpha Numeric is Allowed
        $ImageName = "<ImageName>"

        ######   End Declare Variables #######

        # Create Shared Gallery
        New-AzGallery -GalleryName $sigGalleryName -ResourceGroupName $AIBResourceGroup -Location $location

        # Create Gallery Definition - Is the wrapper around the Image in order to use Shared Image Gallery
        New-AzGalleryImageDefinition -GalleryName $sigGalleryName -ResourceGroupName $AIBResourceGroup -Location $location -Name $ImageName -OsState generalized -OsType 'Windows' -Publisher $publisherName -Offer $offerName -Sku $skuName -Description $description -HyperVGeneration $generation -Feature $features
    }
}
catch {
    Write-Host $_
    Exit;
   }
```
---
## Step 8: Create Master Virtual Machine

You can now create a Master VM and installed required applications. You can skip this step if you plan to use and existing VM but ensure for AVD you may want to use a  Multi-Session VM for Pooled Deployment.

---

## Step 9: Run the VDOT Script for Improved Performance

Now that you have the Master VM Created, you may want to run the VDOT Tool.

The Virtual Desktop Optimization Tool (VDOT) is a set of mostly text-based tools that apply settings to a Windows operating system, intended to improve performance. The performance gains are in overall startup time, first logon time, subsequent logon time, and usability during a user-session.

Refer for more information - https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool

```powershell
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
```
---
## Step 10: Create Image form Master VM without Destroying

This is the final step for creating an Image using the Master VM and storing it in the Shared Image Gallery.

The script creates a snapshot and provisions a temp VM to generate an Image by doing this we are preserving the Master VM for future use, optionally this script can perform cleanup if the $delSnap is set to $true.

```powershell
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
    $delSnap = $false

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
```
---
## Optional: For DevOPS

This is an optional Script we want to use for DevOPS Pipeline.

```powershell
Try {
       $context = Get-AzContext
        If (!$context) {
        Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";
        }
       
        else {
######   Declare Variables #######

# Set Image Name
$imageName = "<ImageName>"

# Set the Location
$location = "<Location>"

# Specify Subscription ID
$SubscriptionID = "<SubscriptionID>"

# Set the Resource Group
$aibRG = "<AIBResourceGroup>"

# Specify Managed Identity
$ManagedIdentityName = "<ManagedIdentity>"

# Define VNET and Subnet
$VNETName = "<VNetName>"
$SubnetName = "<SubnetName>"
$VNetRG = "<VNetResourceGroup>"

# Specify the Shred Image Gallery Name - Only Alpha Numeric is Allowed
$sigGalleryName = "<GalleryName>"
$sigRG = "<GalleryResouceGroup>"
$ImageName = "<ImageName>"
$RepLocation = "<ReplicationLocation>"

# Define Properties for Image
$ImageTemplateName = "Windows1122H2"
$ImagePublisher = "microsoftwindowsdesktop"
$ImageOffer = "office-365"
$ImageSKU = "win11-22h2-avd-m365"

######   End Declare Variables #######

# Get the ID of Managed Identity
$ManagedIdentityId = $(Get-AzUserAssignedIdentity -ResourceGroupName $aibRG -Name $ManagedIdentityName).Id

# Disable Private Link Service Policy
$VNetInfo =  Get-AzVirtualNetwork -Name $VNETName -ResourceGroupName $VNETRG
($VNetInfo | Select -ExpandProperty subnets | Where-Object  {$_.Name -eq $SubnetName} ).privateLinkServiceNetworkPolicies = "Disabled"  
$VNetInfo  | Set-AzVirtualNetwork 

# Getting Subnet ID
$SubnetId = "/subscriptions/$SubscriptionID/resourceGroups/$VNetRG/providers/Microsoft.Network/virtualNetworks/$VNETName/subnets/$SubnetName"

# Build VM Profile
$vmProfile = [pscustomobject]@{
        osDiskSizeGB=150
        vmSize="Standard_D8s_v3"
        vnetConfig=[pscustomobject]@{subnetId=$SubnetId}
}

$ImageDefinationId = "/subscriptions/$SubscriptionID/resourceGroups/$sigRG/providers/Microsoft.Compute/galleries/$sigGalleryName/images/$ImageName"

$SIGLocations=$location,$RepLocation

# Output File
$ImageTemplateFileOut = "AIB-Win11.json"

# Build JSON
$TemplateJSON = Get-Content 'ImageTemplate.json.dist' -raw | ConvertFrom-Json
$TemplateJSON.location=$location
$TemplateJSON.tags.ImagebuilderTemplate=$ImageTemplateName
$TemplateJSON.properties.source.publisher = $ImagePublisher
$TemplateJSON.properties.source.offer = $ImageOffer
$TemplateJSON.properties.source.sku = $ImageSKU
$dist=$TemplateJSON.properties.distribute[0]
$dist.Type = "SharedImage"
$dist.runOutputName = $imageName
$dist.PSObject.Properties.Remove('imageId')
$dist.PSObject.Properties.Remove('location')
$dist | Add-Member -NotePropertyName galleryImageId -NotePropertyValue $ImageDefinationId
$dist | Add-Member -NotePropertyName replicationRegions -NotePropertyValue $SIGLocations
$dist.artifactTags.baseosimg = "windows11m365"
$TemplateJSON.identity.userAssignedIdentities = [pscustomobject]@{$ManagedIdentityId=[pscustomobject]@{}}
$TemplateJSON.properties.distribute[0]=$dist
$TemplateJSON.properties | Add-Member -NotePropertyName vmProfile -NotePropertyValue $vmProfile
$TemplateJSON | ConvertTo-Json -Depth 4 | Out-File $ImageTemplateFileOut -Encoding ascii

# Validation:
#code AIB-ChocoWin11.json
#$TemplateJSON.properties.vmProfile.vmSize
#$TemplateJSON.properties.customize | Select-Object type,name
#$TemplateJSON.properties.customize[0].inline
#$TemplateJSON.properties.customize[1].inline
#$TemplateJSON.properties.customize[1].validExitCodes


# If there was a Failed Attempt and you want to Delete and re-create template
Remove-AzImageBuilderTemplate -Name $imageName -ResourceGroupName $aibRG

# Create Image Template  
az image builder create -g $aibRG -n $imageName --image-template $ImageTemplateFileOut

# Build the image
az image builder run -n $imageName -g $aibRG

# Check last status
az image builder show --name $imageName --resource-group $aibRG --query lastRunStatus -o table
        }
}

catch {
        Write-Host $_
        Exit;
       }
```
---

## Next Steps

You can now build VMs from the Image, or deploy it while you configure Azure Virtual Desktop

https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-9.0.1&viewFallbackFrom=azps-2.5.0#examples
https://learn.microsoft.com/en-us/azure/virtual-desktop/overview

---
