<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, we are creating Shared Image Gallery.
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    
    The user account deploying AIB should be Global Admin/Owner to perform required changes
    You can define Gallery Properties as you seem relevant.
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
