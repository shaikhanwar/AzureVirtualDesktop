Try {

    $context = Get-AzContext

    If (!$context) {

            Write-Host "You're not connected to AzureAD. Run the SetEnvironment.Ps1 to get started";

            
        }

else {

# Specify VNet Resource Group
$VNetRG = "currentenv"

# AIB Image Defination Name - Unique" not used yet
$AIBImageDefName = "Azure Image Builder Image Custom Role"

$AIBGitCreationUrl = "https://raw.githubusercontent.com/shaikhanwar/AzureVirtualDesktop/main/AIBPermission.json"

$ImageCreationPath = "AIBPermission.json"

# download config
Invoke-WebRequest -Uri $AIBGitCreationUrl -OutFile $ImageCreationPath -UseBasicParsing

((Get-Content -path $ImageCreationPath -Raw) -replace '<subscriptionID>',$SubscriptionID) | Set-Content -Path $ImageCreationPath
((Get-Content -path $ImageCreationPath -Raw) -replace '<rgName>', $VNetRG) | Set-Content -Path $ImageCreationPath
((Get-Content -path $ImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $AIBImageDefName) | Set-Content -Path $ImageCreationPath

# create role definition
New-AzRoleDefinition -InputFile  ./AIBPermission.json

# Grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $AIBImageDefName -Scope "/subscriptions/$SubscriptionID/resourceGroups/$AIBResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
##https://docs.microsoft.com/en-us/azure/role-based-access-control/troubleshooting

    }

}

catch {

    Write-Host $_
    
    Exit;
    
    }