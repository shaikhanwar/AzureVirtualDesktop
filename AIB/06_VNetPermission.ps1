<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, we are creating a Custom Role for AIB and Granting it to the Managed Identity to read VNet Configuration.
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