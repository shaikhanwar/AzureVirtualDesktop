 <#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, for DevOPS.
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    
    The user account deploying AIB should be Global Admin/Owner to perform required changes
    This script uses an existing JSON Template "ImageTemplate.json.dist" to further customize and create an Image
  
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