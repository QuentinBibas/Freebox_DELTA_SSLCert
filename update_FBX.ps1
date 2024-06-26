#################################################################################
#                                update_box.ps1                                 #
#    updates the Freebox DELTA domain certificate from the web GUI              #
#       relies on Selenium and Chrome                                           #
#       c:\temp must exist with read/write rights for the script user           #
#    this considers using an ECDSA cert, obtained through Win-ACME              #
#                                                                               #
#  v1.1                                                          18/04/2024     #
#################################################################################

######### settings ####################
$certlocation = "C:\WACS\PEM_Certs\" # location where the certificate is created  
$freeboxUI = "http://1.2.3.4" # IP of the Freebox UI < must use http and IP since we must remove the existing cert to update it through the GUI
$domain = "box.example.com" # the FQDN you're using for your freebox - beware, this script relies on the fact that the certificate files are named after that FQDN !
$freeboxpassword = 'PA$$WORD' # password of the admin console for the freebox
#$chromedriverpath = "C:\WACS\Scripts\ChromeDriver\" # path to your chromedriver binary | use only if the update mechanism is undesirable
$certtype = "ECDSA" # can be either ECDSA or RSA on the latest to-date Freebox DELTA firmware
$chromeJSONURI = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json" # the URI where the chrome JSON is located

######### routine ######################
# keep chromedriver up to date if $chromedriverpath is not set
if (($chromedriverpath -eq $null) -or ($chromedriverpath -eq "")) {
    #Install Latest Version of Selenium
    Install-Module Selenium -Force
    # Find the latest ChromeDriver release for Win64 from the chrome JSON
    $driverJSON = Invoke-WebRequest -Uri "$chromeJSONURI" | ConvertFrom-Json
    $fullURL = $($driverJSON.channels.Stable.downloads.chromedriver | Where-Object { $_.platform -eq "win64"}).url
    Invoke-WebRequest -Uri $fullURL -OutFile "C:\temp\$(Split-Path $fullURL -leaf)"
    # Expand the archive
    Expand-Archive -LiteralPath "C:\temp\$(Split-Path $fullURL -leaf)" -DestinationPath "c:\temp\" -Force
    # Set chromedriverpath to downloaded folder
    $chromedriverpath= $(Get-ChildItem -Path c:\temp -Recurse -Filter "chromedriver.exe" | % { $_.DirectoryName })
}

# generate certificate names / find the latest ones
$pubkey= $(Get-ChildItem $certlocation | Where-Object { $_.Name -match "crt" } | sort).FullName
$chain= $(Get-ChildItem $certlocation | Where-Object { $_.Name -match "chain-only" } | sort).FullName
$privkey= $(Get-ChildItem $certlocation | Where-Object { $_.Name -match "key" } | sort).FullName

#### browsing logic
# create browser instance
$Url = $freeboxUI
$Driver = Start-SeChrome -WebDriverDirectory $chromedriverpath -Headless
[OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($Driver)

# start navigating to Freebox UI
Enter-SeUrl -Driver $Driver -Url $Url
$Xpath = '//*[@id="ext-comp-1017"]'
$Driver.FindElementByXPath($Xpath).Click()

# login
### we try to login... if we're already logged in and the buttons do not exist, fail silently and move on
Try {
    $Xpath = '//*[@id="menuitem-1038"]'
    $Driver.FindElementByXPath($Xpath).Click()

    $Xpath = '//*[@id="fbx-password"]'
    $Driver.FindElementByXPath($Xpath).SendKeys($freeboxpassword)
    $Xpath = '//*[@id="formContent"]/input[3]'
    $Driver.FindElementByXPath($Xpath).Click()
    }
    Catch {}

# go to settings
$Xpath = '//*[@id="ext-comp-1017"]'
$Driver.FindElementByXPath($Xpath).Click()
$Xpath = '//*[@id="menuitem-1023"]'
$element = $Driver.FindElementByXPath($Xpath)
$actions.MoveToElement($element).Build().Perform()
$Xpath = '//*[@id="menuitem-1025"]'
$Driver.FindElementByXPath($Xpath).Click()

# go to "domain name" settings
$Xpath = '//*[@id="Fbx.os.app.settings.domains.Domains"]'
$element = $Driver.FindElementByXPath($Xpath)
$actions.DoubleClick($element).Build().Perform()

# certificate update routine
### delete the certificate & domain name that are present on the box. If there is none, fail silently and move on
Try {
    $Xpath = '/html/body/div[1]/div[6]/div[2]/div/div[2]/span/div/fieldset/div/span/div/div[2]/div/div/a[1]/span'
    $Driver.FindElementByXPath($Xpath).Click()
    $Xpath = '/html/body/div[7]/div[3]/div/div/a[2]'
    $Driver.FindElementByXPath($Xpath).Click()
    } catch {}

## create the domain name
$Xpath = '/html/body/div[1]/div[6]/div[2]/div/div[1]/div/div/a[2]'
$Driver.FindElementByXPath($Xpath).Click()
Start-Sleep -Seconds 1
$Xpath = '/html/body/div[1]/div[8]/div[2]/div/div[2]/div[1]/div/span/div/table[3]/tbody/tr/td[2]'
$Driver.FindElementByXPath($Xpath).Click()
$Xpath = '/html/body/div[1]/div[8]/div[2]/div/div[3]/div/div/a[2]'
$Driver.FindElementByXPath($Xpath).Click()
$Name = "domain_name"
$Driver.FindElementByName($Name).SendKeys($domain)

$Xpath = '/html/body/div[1]/div[8]/div[2]/div/div[3]/div/div/a[2]'
$Driver.FindElementByXPath($Xpath).Click()
$Xpath = '/html/body/div[1]/div[8]/div[2]/div/div[3]/div/div/a[2]'
$Driver.FindElementByXPath($Xpath).Click()

## SSL certificate input
$Xpath = '/html/body/div[1]/div[8]/div[2]/div/div[2]/div[9]/div/span/div/table[1]/tbody/tr/td[2]/table/tbody/tr/td[2]'
$Driver.FindElementByXPath($Xpath).Click()
########## change the following line to 
$Xpath ="//*[text()='$certtype']"
$Driver.FindElementByXPath($Xpath).Click()

#### certificate data (public key)
$name = "cert_pem"
#$Driver.FindElementByName($name).SendKeys($pubkey)
foreach ( $line in Get-Content $pubkey ) {
    $Driver.FindElementByName($name).SendKeys($line)
    $Driver.FindElementByName($name).SendKeys([Environment]::NewLine)
}
Start-Sleep -Seconds 2
#### private key
$name = "key_pem"
foreach ( $line in Get-Content $privkey ) {
    $Driver.FindElementByName($name).SendKeys($line)
    $Driver.FindElementByName($name).SendKeys([Environment]::NewLine)
}
Start-Sleep -Seconds 2
#### certificate authority (CA) chain from your certificate provider
$name = "intermediates"
foreach ( $line in Get-Content $chain ) {
    $Driver.FindElementByName($name).SendKeys($line)
    $Driver.FindElementByName($name).SendKeys([Environment]::NewLine)
}
Start-Sleep -Seconds 2

$Xpath = '/html/body/div[1]/div[8]/div[2]/div/div[3]/div/div/a[2]'
$Driver.FindElementByXPath($Xpath).Click()
$Xpath = '/html/body/div[1]/div[8]/div[2]/div/div[3]/div/div/a[2]'
$Driver.FindElementByXPath($Xpath).Click()

$Driver.Close()
$Driver.Quit()

# clean c:\tmp before exiting
Get-ChildItem -Path "c:\temp" -Filter "chromedriver*" | Remove-Item -Recurse -Force

exit
