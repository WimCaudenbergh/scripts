## This script requires "requests": http://docs.python-requests.org/
## To install: pip install requests

import json
import requests

FRESHDESK_ENDPOINT = "https://userfull.freshdesk.com" # check if you have configured https, modify accordingly
FRESHDESK_KEY = "SlcYb1f1Uc2orQqieSF6"

#Example: /helpdesk/tickets/30.json
r = requests.get(FRESHDESK_ENDPOINT + '/helpdesk/tickets/1000.json',
        auth=(FRESHDESK_KEY, "X"))

print 'HTTP response code: ' + str(r.status_code)
print 'HTTP response body: ' + str(r.content)
