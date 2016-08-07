#####################################################
# Purpose: Export company users to a csv file.
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
$authorizationCode = ""      			#<-- Visit https://webapi.teamviewer.com/api/v1/oauth2/authorize?response_type=code&client_id=YOURCLIENTIDHERE
                             			#    Login and grant the permissions (popup) and put the code shown in the authorizationCode variable here

# export filename
$exportFileNameUsers = "exportUsers.csv"

# All possible keys are: id, name, permissions, active
$userKeys = 'id, name, permissions, active' 

##########
# includes
##########

$currentPath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path

. (Join-Path $currentPath "Common.ps1")

###########
# Functions
###########

# write as CSV
function WriteCSV($val, $exportFileName)
{
	$userKeys = $userKeys -split ", "
	$path = (Join-Path $currentPath $exportFileName)
	$val | select $userKeys | Export-Csv $path -encoding "unicode" -force -notype
}

#####################
# Main: Export Users as CSV
#####################

Write-Host ("Starting CSV export...")

# check OAuth requirements
if ($clientId -and $authorizationCode) 
{
	#get token
	$token = RequestOAuthAccessToken $clientId $clientSecret $authorizationCode
	if ($token){
		$accessToken = $token
	}
}

# ping API to check connection and token
if (PingAPI($accessToken) -eq $true)
{
	$users = GetAllUsersAPI($accessToken)
	WriteCSV $users $exportFileNameUsers
}
else
{
	Write-Host ("No data exported. Token or connection problem.")
}

Write-Host ("CSV export finished.")