from urllib.request import Request, urlopen
from urllib.error import URLError
from bs4 import BeautifulSoup
from sys import exit
from time import sleep

# config variables
SERVER = "smtp.gmail.com"
FROM = "karimrashad@gmail.com"
TO = ["karim.rashad@trueclarity.co.uk"] # must be a list
SUBJECT = "M48 Severn Bridge Status Change"
TEXT = "The bridge status has changed: "
UNAME = ""
PASSWD = ""
BRIDGEURL = 'https://www.severnbridge.co.uk/Home.aspx?.Parent=status3&FileName=status3'

req = Request(BRIDGEURL)

def getBridgeStatus():
    "This returns the status of the M48 Sever bridge"
    try:
        response = urlopen(req)
    except URLError as e:
        if hasattr(e, 'reason'):
            print('We failed to reach a server.')
            print('Reason: ', e.reason)
            exit(0)
        elif hasattr(e, 'code'):
            print('The server couldn\'t fulfill the request.')
            print('Error code: ', e.code)
            exit(0)
    else:
        html = response.read()

    soup = BeautifulSoup(html, 'html.parser')

    status_button = soup.find(id="ctl05_ctl00_gridList_btnStatusIcon_1")['src']
    if status_button == 'Images/Icons/bridge_green.png':
        return 'Open'
    elif status_button == 'Images/Icons/bridge_yellow.png':
        return 'Closed to high-sided vehicles'
    elif status_button == 'Images/Icons/bridge_red.png':
        return 'Closed'
    else:
        return 'Status error'

def sendStatusChangeMail():
    "This sends an email message about a bridge status change"

    # prepare actual message
    message = """\
    From: %s
    To: %s
    Subject: %s

    %s
    """ % (FROM, ", ".join(TO), SUBJECT, TEXT)

    # send the mail
    server = smtplib.SMTP(SERVER, 587)
    server.starttls()
    server.login(UNAME, PASSWD)
    server.sendmail(FROM, TO, message)
    server.quit()

# main loop
status = 'Open'
n = 1
while(True):
    newStatus = getBridgeStatus();
    if newStatus != status:
        print(n, ": Status changed! Sending mail: " + status)
        status = newStatus
        TEXT = TEXT + status
        sendStatusChangeMail()
    else:
        print(n,": Status unchanged: " + status)
    # wait 5 minutes
    sleep(300)
    n += 1

    


#
# This is the bit of HTML we are scraping for bridge status:
#

# 		<table class="header-table-status-grid" cellspacing="0" currentsort="" id="ctl05_ctl00_gridList" style="border-collapse:collapse;">
# 			<tbody><tr class="header-row">
# 				<th class="left-side-column" scope="col"><a href="javascript:__doPostBack('Root$ctl05$ctl00$gridList','Sort$Name')"></a></th><th scope="col"><a href="javascript:__doPostBack('Root$ctl05$ctl00$gridList','Sort$Status')"></a></th>
# 			</tr><tr>
# 				<td class="left-side-column">
#                      <img id="ctl05_ctl00_gridList_btnStatusIcon_0" src="Images/Icons/bridge_green.png" alt="Status icon">
#                      M4 Second Severn Crossing
#                   </td><td>
#                      Bridge OPEN to all traffic.
#                   </td>
# 			</tr><tr class="alt">
# 				<td class="left-side-column">
#                      <img id="ctl05_ctl00_gridList_btnStatusIcon_1" src="Images/Icons/bridge_green.png" alt="Status icon">
#                      M48 Severn Bridge
#                   </td><td>
#                      Bridge OPEN to all traffic.
#                   </td>
# 			</tr><tr class="footer">
# 				<td class="left-side-column">&nbsp;</td><td>&nbsp;</td>
# 			</tr>
# 		</tbody></table>
