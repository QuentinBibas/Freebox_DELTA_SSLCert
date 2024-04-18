# Freebox_DELTA_SSLCert
Powershell script to update a Freebox DELTA SSL certificate


synopsis :
This script relies on selenium, chrome, and the chromedriver to update the SSL certificate on a Freebox DELTA (french ISP)
If the UI didn't change for the Freebox Ultimate, it might work on it too.

This script implies that you have your own domain and get your own SSL certificate.
In my case, I'm using let's encrypt via WACS / Win-ACME (https://www.win-acme.com/). WACS is set to call the script on its own when renewing the certificate.

How does it work :
The script will update the certificate for the Freebox DELTA using its web GUI, since the API doesn't have any hooks to update it.
To do this, this script relies on Selenium, Chrome, and the chromedriver.
Selenium and the chromedriver are kept up to date from the script. If you do not need that part, you can comment out $chromedriverpath in the settings to disable this mechanism.
As the web GUI gets random IDs for its elements on each run, it relies mostly on the XPaths of the items to navigate to the domain name & certificates parts.
