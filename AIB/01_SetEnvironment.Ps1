<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, required to setup the Login and Subscription Context
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    
    The user account deploying AIB should be Global Admin/Owner to perform required changes
.EXAMPLE
    Refer - https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
#>

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
