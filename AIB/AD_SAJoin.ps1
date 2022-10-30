 <#
.SYNOPSIS

    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB

    Create By :-  Anwar Shaikh

.DESCRIPTION
    This snippet is part of AVD Deployment, to join Storage Account the OnPrem AD.
    https://github.com/shaikhanwar/AzureVirtualDesktop/tree/main/AIB
    
    The user account running this script should be Domain Admin/Global Admin/Owner to perform required changes
      
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

#Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
.\CopyToPSPath.ps1 

# Import AD Module
Import-Module activedirectory

# Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid

# Define parameters for Storage Account
$SubscriptionID = "<SubcriptionID>"
$StorageAccountName = "<StorageAccountName>"
$ResourceGroupName = "<StorageAcResourceGroup>"

# Define Distinguish Name of the AD OU for Storage Account
# To Get-ADOrganizationalUnit –LDAPFilter “(name=scripting)”
$OUName = ""
$DomainName = ""
$DomainNetbiosName = ""
$DCName = ""

# Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionID

# Create Kerberos Keys
New-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -KeyName "kerb1"
New-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -KeyName "kerb2"

# Generate Token
$Token = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.KeyName -eq "kerb1"}).Value


$sessionAD = New-PSSession -ComputerName $DCName
Invoke-Command { Import-Module ActiveDirectory } -Session $sessionAD

# Create Computer Object - You need Domain Admin Permission
New-ADComputer -Name $StorageAccountName -AccountPassword (ConvertTo-SecureString -AsPlainText $Token -Force) -Path $OUName

# If you don’t know the Storage Account Path run the below command to get
#([uri](Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).PrimaryEndpoints.File).Host

# Register SPN - You need Domain Admin Permission
Set-ADComputer -Identity $StorageAccountName -ServicePrincipalNames @{Add="cifs/avdprdshare.file.core.windows.net"}

# Updating AD Computer Object for AD - You need Domain Admin Permission
$DomainGuid = (Get-ADDomain -Identity $DomainName).ObjectGuid.Guid
$DomainSid = (Get-ADDomain -Identity $DomainName).DomainSID.Value
$StorAccountSid = (Get-ADComputer -Identity $StorageAccountName).SID.Value
 
$Splat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $StorageAccountName
    EnableActiveDirectoryDomainServicesForFile = $true
    ActiveDirectoryDomainName = $DomainName
    ActiveDirectoryNetBiosDomainName = $DomainNetbiosName
    ActiveDirectoryForestName = $DomainNetbiosName
    ActiveDirectoryDomainGuid = $DomainGuid
    ActiveDirectoryDomainsid = $DomainSid
    ActiveDirectoryAzureStorageSid = $StorAccountSid
}
Set-AzStorageAccount @Splat

# Update Encryption to AES256
Update-AzStorageAccountAuthForAES256 -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

# You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose

# Confirm Feature
$storageaccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

# List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions

# List the directory domain information if the storage account has enabled AD DS authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties

}
}

catch {
    Write-Host $_
    Exit;
    }




