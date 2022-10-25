## Abstracts

# **Using PowerShell to Create a Windows Virtual Desktop Custom Image using Azure VM Image Builder**

---
## Workshop

In this workshop, you will automate using the Azure VM Image Builder, and distibute to the Azure Shared Image Gallery, where you can replicate regions, control the scale, and share inside and outside your organizations. To simplify deploying an AIB configuration template with PowerShell CLI.

This walk through is intended to be a copy and paste exercise however you may have to specify key variable values pertaining to your environment, and will provide you with a custom Windows 11 22H2 Multi Session Server image, showing you how you can easily create a custom image.

---
## Step 1: Set up Login and context

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
$Location = "EastUS"

}

catch {

     Write-Host $_
    
     Exit;

    }

```
---
## Step 2: Register Providers for Azure Image Builder
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
