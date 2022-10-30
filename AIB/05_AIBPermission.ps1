<#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AIB Deployment, we are creating a Custom Role for AIB and Granting it to the Managed Identity.
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