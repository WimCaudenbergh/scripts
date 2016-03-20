## This script requires "requests": http://docs.python-requests.org/
## To install: pip install requests

import json
import requests
import base64

FRESHDESK_ENDPOINT = "https://userfull.freshdesk.com" # check if you have configured https, modify accordingly
FRESHDESK_KEY = "SlcYb1f1Uc2orQqieSF6"

base64string = base64.encodestring('%s:%s' % (FRESHDESK_KEY, "X"))
auth = "Basic %s" % base64string
headers = {'Authorization': auth}

r = requests.get(FRESHDESK_ENDPOINT + '/helpdesk/tickets.json', headers = headers)

print 'HTTP response code: ' + str(r.status_code)
print 'HTTP response body: ' + str(r.content)