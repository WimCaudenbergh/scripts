#####################################################
# Purpose: Sync company member with an ActiveDirectory Group.
# 
# Copyright (c) 2014 TeamViewer GmbH
# Example created 2014-02-20
# Version 1.1
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#####################################################

###############
# Configuration
###############

# API access token 
$accessToken = "XX-XXXXXXXXXXXXXXXXXXXX" #<-- your access token, can be left empty when OAuth (below) is configured.

# OAuth: API client id & authorizationCode
# if all variables are set here, OAuth will be used to request an access token
$clientId = ""            				#<-- Create an app in your TeamViewer Management Console and insert the client ID here.
$clientSecret = ""						#<-- Insert your client secret here.
$authorizationCode = ""      #<-- Visit https://webapi.teamviewer.com/api/v1/oauth2/authorize?response_type=code&client_id=YOURCLIENTIDHERE
                             #    Login, grant the permissions (popup) and put the code shown in the authorizationCode variable here

# domain settings
$dn = "dc=testad,dc=local"

# ldap settings
$dcIP = "127.0.0.1"
$dcLdapPort = "389"

# user group to sync with management console
$syncGroupCN = "tvuser"
$syncGroupOU = "myUsers"
$syncGroupSearchFilter = "(&(objectCategory=user)(memberOf=cn=$syncGroupCN,ou=$syncGroupOU,$dn))"

# new user defaults (if not available in csv import file)
$defaultUserLanguage = "en"   
$defaultUserPassword = "myInitalPassword!"
$defaultUserPermissions = "ShareOwnGroups,EditConnections,EditFullProfile,ViewOwnConnections"

# deactivate company users not found in the configured AD group 
$deactivateUnknownUsers = $false
# testRun needs to be set to false for the script to perform actual changes
$testRun = $true

##########
# includes
##########

$currentPath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

. (Join-Path $currentPath "Common.ps1")

###########
# Functions
###########

# Returns the AD members of the configured usergroup from above
function GetADMembersOfOU()
{
	Write-Host 
	Write-Host "Reading AD OU members"

	$result2 = $NULL

	try
	{
		$domain = "LDAP://" + $dcip + ":" + $dcLdapPort + "/$dn"
	    $root = New-Object System.DirectoryServices.DirectoryEntry $domain
	    
	    $query = new-Object System.DirectoryServices.DirectorySearcher
	    $query.searchroot = $root        
	    $query.Filter = $syncGroupSearchFilter
	    
	    #needed user properties
	    $colProplist = "name", "mail", "givenName", "sn", "department", "description", "userAccountControl"
	    
	    foreach ($i in $colPropList)
	    {
	        [void]$query.PropertiesToLoad.Add($i)
	    }    
	    
	    $result2 = $query.findall()

		$userDict = @{}
		
	    foreach ($objResult in $result2)
	    {
			$user = @{}
			
			$user["email"] = [string]$objResult.Properties.mail
			$user["name"] = [string]($objResult.Properties.givenname + $objResult.Properties.sn)
			
			#check user account status (00000000000000000000000000000010 binary, 2 decimal, UF_ACCOUNT_DISABLE)
			$uacVal = $objResult.Properties.useraccountcontrol.Item(0)
			$userEnabled = (($uacVal -BAND 2) -eq 0)
			
			#skip user when required fields are missing, or account is disabled
			if($user.email.length -gt 0 -and $user.name.length -gt 0 -and $userEnabled -eq $true)
			{
				$userDict.Add([PSCustomObject]$user.email, [PSCustomObject]$user)
			}
			else
			{
			 	Write-Host "AD user is missing name and/or email. Skipped."
			}
	    }
		
	
		$result2 = $userDict
	}
	catch [Exception]
	{
		Write-Host ("AD read failed! The error was '{0}'." -f $_)
		$result2 = $NULL
	}
	finally 
	{
		return $result2
	}
}

#######################################
# Sync AD Usergroup with TeamViewer API
#######################################

if($testRun -eq $true)
{
	Write-Host "testRun is set to true. Information in your TeamViewer account will not be modified. Instead, all changes that would be made are displayed on the console. Press any key to continue..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
Write-Host ("Starting AD OU Sync...")

# check OAuth requirements
if ($clientId -and $authorizationCode) 
{
	#get token
		$token = RequestOAuthAccessToken $clientId $clientSecret $authorizationCode
	if ($token){
		$accessToken = $token
	}
}

#ping API to check connection and token
if (PingAPI($accessToken) -eq $true)
{
    #read users from the AD OU	
	$dictUsersAD = GetADMembersOfOU
	
    #get all current users of our company from the API
	$arrUsersAPI = GetAllUsersAPI $accessToken
	
	#put all current API users in a dictionary, id field as key
	$dictUsersAPI = @{}
	foreach ($u in $arrUsersAPI)
	{
		#Write-Host $u.id
		$dictUsersAPI.Add($u.id, $u)	
	}
	
	#sync
	#for each user in AD group: check against API if user exists (by mail)	
	foreach($usrKey in $($dictUsersAD.keys))
	{
		#Write-Host $usrKey
	
		$userApi = $null
		$userAD = $null
		
		$userAD = $dictUsersAD[$usrKey]
		$userApi = GetUserByMail $accessToken $usrKey #lookup API user by mail	
		
		if($userApi) #user found -> update user
		{ 
			Write-Host
			Write-Host "User with email=" $usrKey " found."
			
			if ($testRun -eq $true)
			{
				Write-Host "UpdateUser: " $usrKey " with this values:"
				$userAD.GetEnumerator() | Foreach-Object {
					Write-Host $_.Key " = " $_.Value
				}
				Write-Host
				$dictUsersAPI.Remove($userApi.id)
			}
			else
			{
			#Update the user
			UpdateUser $accessToken $userApi.id $userAD
			#remove this user from our dictionary
			$dictUsersAPI.Remove($userApi.id)
			}
		}
		else #no user found -> create user
		{
			Write-Host
			Write-Host "No user with email=" $usrKey " found."
			
			if ($testRun -eq $true)
			{
				Write-Host "CreateUser: " $usrKey " with this values:"
				$userAD.GetEnumerator() | Foreach-Object {
					Write-Host $_.Key " = " $_.Value
				}
				Write-Host
			}
			else
			{
            #Create User
            CreateUser $accessToken $userAD $defaultUserPermissions $defaultUserLanguage $defaultUserPassword
			}
		}		
	}
	
	# if configured, delete all users not in AD group
    if ($deactivateUnknownUsers -eq $true)
	{
		if ($testRun -eq $true)
		{
			Write-Host "Deactivate Unknown Users:"
			#$dictUsersAPI.GetEnumerator() | Foreach-Object {
			#	Write-Host "DeactivateUser: id = " $_.Key " name = " $_.Value["name"]
			#}
			foreach( $id in $($dictUsersAPI.Values))
			{
				Write-Host "DeactivateUser: id = " $id.id " name: " $id.name
			}
			Write-Host
		}
		else
		{
			#all users remaining in dictUsersAPI dictionary are not present in the AD group an can be deactivated
			foreach( $id in $($dictUsersAPI.Keys))
			{
				DeactivateUser $accessToken $id		
			}
		}
	}
}
else
{
	Write-Host ("No data imported. Token or connection problem.")
}
 
Write-Host ("AD OU Sync finished.")