# Freebox_DELTA_SSLCert
Powershell script to update a Freebox DELTA SSL certificate


synopsis :
This script relies on selenium, chrome, and the chromedriver to update the SSL certificate on a Freebox DELTA (french ISP)
If the UI didn't change for the Freebox Ultimate, it might work on it too.

This script implies that you have your own domain and get your own SSL certificate.
In my case, I'm using let's encrypt via WACS (https://www.win-acme.com/). WACS is set to call the script on its own when renewing the certificate.

It relies mostly on the XPaths of the items to navigate to the domain name & certificates parts.
