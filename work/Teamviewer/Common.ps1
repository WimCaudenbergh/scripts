#####################################################
# Purpose: Helper functions to support API scripting examples.
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

##########
# includes
##########

# JSON 1.7 (JSON 1.7.ps1):
#   Author: Joel Bennett
#   Date: 2011-8-1
#   Website: http://poshcode.org/2930
#   Creative Commons: No Rights Reserved (CC0)

. (Join-Path $currentPath "JSON 1.7.ps1")

##################
# script variables
##################

# version of the TeamViewer API
$apiVersion = "v1"

# url of the TeamViewer Management Console API
$tvApiBaseUrl = "https://webapi.teamviewer.com"

###############
# API Functions
###############

# OAuth2: get an access token by clientId and authorizationCode 
function RequestOAuthAccessToken($clientId, $clientSecret, $authorizationCode) 
{
	Write-Host ("")
	Write-Host ("Get token...")
	Write-Host ("Request [POST] /api/$apiVersion/oauth2/token")
    $result = $false	

    try {        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/oauth2/token")
        $req.Method = "POST"
		$req.ContentType = "application/x-www-form-urlencoded"        
		
		$payload = "grant_type=authorization_code&code=" + $authorizationCode + "&client_id=" + $clientId + "&client_secret=" + $clientSecret
		$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
		
		Write-Host "Payload: $payload"
		$requestStream = $req.GetRequestStream()
    	$requestStream.Write($payloadBytes, 0,$payloadBytes.length)
    	$requestStream.Close()

        $res = $req.GetResponse()
		$statusStr = $res.StatusCode		
		$statusCode = [int]$res.StatusCode
		
		Write-Host "$statusCode $statusStr"

        $resstream = $res.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $result = $sr.ReadToEnd()		
		
		if($statusCode -ne 200)
		{
			Write-Host "Unexpected response code. Received content was:"
			Write-Host $result
			$result = $false
			return $result
		}		
        
        $jsonResponse = ConvertFrom-Json -InputObject $result -Type String    
        $result =  $jsonResponse.access_token
		
		Write-Host "Token received."		
    }
    catch {
        Write-Host ("Token: Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value
        
		$result = $false
    } 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
        }
		
        return $result
    }
}

# Check if API is available and verify token is valid
function PingAPI($accessToken) 
{
	Write-Host ("")
	Write-Host ("Ping API...")
	Write-Host ("Request [GET] /api/$apiVersion/ping")
    $result = $false	

    try {
        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/ping")
        $req.Method = "GET"
        $req.Headers.Add("Authorization: Bearer $accessToken")		

        $res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode
		
		Write-Host "$statusCode $statusStr"

        $resstream = $res.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $result = $sr.ReadToEnd()
		
		if($statusCode -ne 200 )
		{
			Write-Host "Unexpected response code. Received content was:"
			Write-Host $result
			$result = $false
			return $result
		}
		
        $jsonResponse = ConvertFrom-Json -InputObject $result -Type String    
        $tokenValue =  $jsonResponse.token_valid

		if($tokenValue -eq $true)
		{
			Write-Host ("Ping: Token is valid")
			$result = $true
		}
		else
		{		
			Write-Host ("Ping: Token is invalid")
			$result = $false
		}		
    }
    catch {
        Write-Host ("Ping: Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value
		
        $result = "false"
    } 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
        }
        
        return $result
    }
}

# get all users of a company with all available fields
function GetAllUsersAPI($accessToken) 
{
    Write-Host ("")
    Write-Host ("Get all users...")
	Write-Host ("Request [GET] /api/$apiVersion/users?full_list=true")
    $result = $false

    try {        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/users?full_list=true")
        $req.Method = "GET"
        $req.Headers.Add("Authorization: Bearer $accessToken")

        $res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode
		
		Write-Host "$statusCode $statusStr"

		if($statusCode -ne 200 )
		{
			Write-Host "Unexpected response code. Received content was:"
			Write-Host $result
			$result = $false
			return $result
		}
		
        $resstream = $res.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $result = $sr.ReadToEnd()
        
        $jsonResponse = ConvertFrom-Json -InputObject $result -Type String    
        $result =  $jsonResponse.users 
        Write-Host ("Request ok!")
    }
    catch [Net.WebException] {        
        Write-Host ("Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value		
		
        $result = $false
    } 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
        }
        
        return $result
    }
}

# get a single company user, identified by email
function GetUserByMail($accessToken, $strMail) 
{
	Write-Host ("")
	Write-Host ("Get single user by mail ($strMail)...")
	Write-Host ("Request [GET] /api/$apiVersion/users?email=$strMail&full_list=true")
    $result = $false

    try {        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/users?email=" + $strMail + "&full_list=true")
        $req.Method = "GET"
        $req.Headers.Add("Authorization: Bearer $accessToken")

        $res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode
		
		Write-Host "$statusCode $statusStr"

		if($statusCode -ne 200 )
		{
			Write-Host "Unexpected response code. Received content was:"
			Write-Host $result
			$result = $false
			return $result
		}
		
        $resstream = $res.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $result = $sr.ReadToEnd()
        
        $jsonResponse = ConvertFrom-Json -InputObject $result -Type String    
        $result =  $jsonResponse.users
        Write-Host ("Request ok!")		
    }
    catch [Net.WebException] {        
        Write-Host ("Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value		
		
        $result = $false
    } 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
        }
        
        return $result
    }
}

#Updates a single company user:
#   Field values in $dictUser will be used to update the given user id ($updateUserId)
#   if email should be updated, the dict must declare a column "newEmail" with the new email value
Function UpdateUser($strAccessToken, $updateUserId, $dictUser)
{
	Write-Host ("")
	Write-Host ("Updating user [" + $dictUser.email + "]...")
	Write-Host ("Request [PUT] /api/$apiVersion/users/" + $updateUserId )
    $result = $false

    try {        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/users/" + $updateUserId)
        $req.Method = "PUT"
        $req.Headers.Add("Authorization: Bearer $accessToken")		
		$req.ContentType = "application/json; charset=utf-8"        

		#define update fields		
		$updatePayload = @{}

		#name parameter
		if($dictUser.PSObject.Properties.Match('name') -and $dictUser.name.length -gt 0)
		{
			$updatePayload.name = $dictUser.name			
		}
		
		#password parameter
		if($dictUser.PSObject.Properties.Match('password') -and $dictUser.password.length -gt 5)
		{
			$updatePayload.password = $dictUser.password			
		}
		
		#permission parameter
		if($dictUser.PSObject.Properties.Match('permissions') -and $dictUser.permissions.length -gt 0)
		{
			$updatePayload.permissions = $dictUser.permissions			
		}

		#email parameter (column newMail must exist)
		if($dictUser.PSObject.Properties.Match('newMail') -and $dictUser.newMail.length -gt 5)
		{
			$updatePayload.email = $dictUser.newMail			
		}

		#active parameter (assume every user to be updated is also active per default)    
		if($dictUser.PSObject.Properties.Match('active') -and $dictUser.active.length -gt 0)
		{
			$updatePayload.active = $dictUser.active
		}
		else
		{
			$updatePayload.active = $true
		}		
		
		$psobject = new-object psobject -Property $updatePayload		
		$jsonPayload = $psobject | ConvertTo-Json -NoTypeInformation -Depth 1		
		
		#workaround for bug in ConvertTo-Json function in combination with hashtables (should not be required when porting to PS 3.0)
		#cut out the nested object 
		$innerObjStart = $jsonPayload.LastIndexOf('{')
		$innerObjEnd = $jsonPayload.IndexOf('}') + 1		
		$jsonPayload = $jsonPayload.Substring($innerObjStart, $innerObjEnd - $innerObjStart)
		
		Write-Host "Payload: $jsonPayload"
		
		$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)		
		$requestStream = $req.GetRequestStream()
    	$requestStream.Write($payloadBytes, 0,$payloadBytes.length)
    	$requestStream.Close()

        $res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode		
		Write-Host "$statusCode $statusStr"
		
		if ($statusCode -eq 204)
		{
			Write-Host "User updated."
			[void]$result = $true
		}
		else
		{
			Write-Host "Error updating user."
			[void]$result = $false
		}
    }
    catch [Net.WebException] {        
        Write-Host ("Request failed! The error was '{0}'." -f $_)

		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value
		
        $result = $false
    } 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
        }
        
        return $result
    }
}

#Creates a single company user:
#   Field values in $dictUser will be used to create the given user.
#   Defaults for some missing fields (permissions, password, language) must be provided.
Function CreateUser($strAccessToken, $dictUser, $strDefaultUserPermissions, $strDefaultUserLanguage, $strDefaultUserPassword )
{
	Write-Host ("")
	Write-Host ("Creating user [" + $dictUser.email + "]...")
	Write-Host ("Request [POST] /api/$apiVersion/users")
    $result = $false

    try {        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/users")
        $req.Method = "POST"
        $req.Headers.Add("Authorization: Bearer $accessToken")		
		$req.ContentType = "application/json"

		#define fields		
		$createPayload = @{}

		#name parameter
		if($dictUser.PSObject.Properties.Match('name') -and $dictUser.name.length -gt 0)
		{
			$createPayload.name = $dictUser.name			
		}
		else
		{
			Write-Host ("Field [name] is missing. Can't create user.")
			return $false
		}
		
		#email parameter
		if($dictUser.PSObject.Properties.Match('email') -and $dictUser.email.length -gt 5)
		{
			$createPayload.email = $dictUser.email			
		}
		else
		{
			Write-Host ("Field [email] is missing. Can't create user.")
			return $false
		}		
		
		#password parameter
		if($dictUser.PSObject.Properties.Match('password') -and $dictUser.password.length -gt 5)
		{
			$createPayload.password = $dictUser.password
		}
		else
		{
			$createPayload.password = $strDefaultUserPassword
		}
		
		#permission parameter
		if($dictUser.PSObject.Properties.Match('permissions') -and $dictUser.permissions.length -gt 0)
		{
			$createPayload.permissions = $dictUser.permissions			
		}
		else
		{
			$createPayload.permissions = $strDefaultUserPermissions
		}
		
		#language parameter
		if($dictUser.PSObject.Properties.Match('language') -and $dictUser.language.length -gt 0)
		{
			$createPayload.language = $dictUser.language			
		}
		else
		{
			$createPayload.language = $strDefaultUserLanguage
		}
		
		$psobject = new-object psobject -Property $createPayload		
		$jsonPayload = $psobject | ConvertTo-Json -NoTypeInformation -Depth 1		
		
		#<--workaround for bug in ConvertTo-Json function in combination with hashtables (should not be required when porting to PowerShell 3.0)
			#cut out the nested object 
			$innerObjStart = $jsonPayload.LastIndexOf('{')
			$innerObjEnd = $jsonPayload.IndexOf('}') + 1		
			$jsonPayload = $jsonPayload.Substring($innerObjStart, $innerObjEnd - $innerObjStart)
		#-->
		
		Write-Host "Payload: $jsonPayload"
		
		$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)		
		$requestStream = $req.GetRequestStream()
    	$requestStream.Write($payloadBytes, 0, $payloadBytes.length)
    	$requestStream.Close()

        $res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode		
		Write-Host "$statusCode $statusStr"
		
		if ($statusCode -eq 200)
		{
			Write-Host "User created."
			[void]$result = $true
		}
		else
		{
			Write-Host "Error creating user."
			[void]$result = $false
		}
    }
    catch [Net.WebException] {        
        Write-Host ("Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value
		
        $result = $false
    } 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
        }
        
        return $result
    }
}

#Deactivates a single company user:
Function DeactivateUser($strAccessToken, $userId)
{
	Write-Host ("")
	Write-Host ("Deactivating user [" + $userId + "]...")
	Write-Host ("Request [PUT] /api/$apiVersion/users/" + $userId )
    $result = $false

    try {        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/users/" + $userId)
        $req.Method = "PUT"
        $req.Headers.Add("Authorization: Bearer $accessToken")		
		$req.ContentType = "application/json; charset=utf-8"        

		#define update fields		
		$updatePayload = @{}

		#active flag
		$jsonPayload = "{""active"": false}"
		
		Write-Host "Payload: $jsonPayload"
		
		$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)		
		$requestStream = $req.GetRequestStream()
    	$requestStream.Write($payloadBytes, 0,$payloadBytes.length)
    	$requestStream.Close()

        $res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode
		Write-Host "$statusCode $statusStr"
		
		if ($statusCode -eq 204)
		{
			Write-Host "User deactivated."
			[void]$result = $true
		}
		else
		{
			Write-Host "Error deactivating user."
			[void]$result = $false
		}
    }
    catch [Net.WebException] {        
        Write-Host ("Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value
		
        $result = $false
    } 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
        }
        
        return $result
    }

}
# get all connections of a company with all available fields
function GetAllConnectionsAPI($accessToken) 
{
    Write-Host ("")
    Write-Host ("Get all connections...")
	Write-Host ("Request [GET] /api/$apiVersion/reports/connections")
    $result = $false

    try {        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/reports/connections")
        $req.Method = "GET"
        $req.Headers.Add("Authorization: Bearer $accessToken")

        $res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode
		
		Write-Host "$statusCode $statusStr"

		if($statusCode -ne 200 )
		{
			Write-Host "Unexpected response code. Received content was:"
			Write-Host $result
			$result = $false
			return $result
		}
		
        $resstream = $res.GetResponseStream()
		$sr = new-object System.IO.StreamReader $resstream
		$result = $sr.ReadToEnd()
        
		
        $jsonResponse = ConvertFrom-Json -InputObject $result -Type String

		if ($jsonResponse.next_offset)
		{
			$moreConnections = GetMoreConnectionsAPI $accessToken $jsonResponse
			$result = $moreConnections
		}
		else
		{
		$storedConnections = @{}
        $connections =  $jsonResponse.records
		$storedConnections.Add("Connections 0", $connections)
		$result = $storedConnections
        Write-Host ("Request ok!")
		}
    }
    catch [Net.WebException] {        
        Write-Host ("Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value		
		
        $result = $false
    } 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
        }
        
        return $result
    }
}

function GetMoreConnectionsAPI($strAccessToken, $connectObj)
{
	$accessToken = $strAccessToken
	$jsonResponse = $connectObj
	$moreConnUrl = ""
	[int]$i = 0

	$storedConnections = @{}

	# do as long as there is an item "next_offset" in json file
	while ($jsonResponse.next_offset)
	{
		Write-Host "More connections found..."

		# store connections in dict
		If ($jsonResponse.records)
		{
			$moreConnections = $jsonResponse.records
			$storedConnections.Add("Connections $i", $moreConnections)
			$moreConnUrl = "?offset_id=" + $jsonResponse.next_offset
		}

		Write-Host ("")
		Write-Host ("Get more connections...")
		Write-Host ("")
		$result = $false

		try {        
			$req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/reports/connections" + $moreConnUrl)
			$req.Method = "GET"
			$req.Headers.Add("Authorization: Bearer $accessToken")

			$res = $req.GetResponse()
			$statusStr = $res.StatusCode
			$statusCode = [int]$res.StatusCode
		
			Write-Host "$statusCode $statusStr"

			if($statusCode -ne 200 )
			{
				Write-Host "Unexpected response code. Received content was:"
				Write-Host $result
				$result = $false
				return $result
			} #end if
		
			$resstream = $res.GetResponseStream()
			$sr = new-object System.IO.StreamReader $resstream
			$result = $sr.ReadToEnd()
        
		
			$jsonResponse = ConvertFrom-Json -InputObject $result -Type String
			} # End try

			catch [Net.WebException] {        
			Write-Host ("Request failed! The error was '{0}'." -f $_)
		
			Write-Host "Received content was:"		
			$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
			$sr = new-object System.IO.StreamReader $resstream
			$value = $sr.ReadToEnd()
			Write-Host $value		
		
			$result = $false
			}# End catch
			$i = $i+1
	} #End While

	# store the last connections in dict
	If ($jsonResponse.records)
	{
		Write-Host "No more connections found ..."
		$moreConnections = $jsonResponse.records
		$storedConnections.Add("Connections $i", $moreConnections)
	}

	return $storedConnections



}