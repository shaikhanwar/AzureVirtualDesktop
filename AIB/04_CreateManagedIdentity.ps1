<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, to create Managed Identity for AIB.
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
