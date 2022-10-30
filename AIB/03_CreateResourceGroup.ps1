<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, to create resource groups for AIB.
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