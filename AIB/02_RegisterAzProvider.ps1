<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, to register required providers for AIB.
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    
    The user account deploying AIB should be Global Admin/Owner to perform required changes
.EXAMPLE
    Refer - https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
#>

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