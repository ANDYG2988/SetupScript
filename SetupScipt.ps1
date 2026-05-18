#Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# ---------------- FUNCTIONS ---------------- #
function Update-AllPackages {
    Write-Host "Updating all installed packages..." -ForegroundColor Yellow
    try {
        winget upgrade --all --accept-package-agreements --accept-source-agreements -h
        Write-Host "All packages updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to update packages: $_" -ForegroundColor Red
    }
}

function Rename-PC {
    $NewName = Read-Host "Enter the new computer name"
    if ([string]::IsNullOrWhiteSpace($NewName)) {
        Write-Host "No name entered. Skipping rename." -ForegroundColor Yellow
        return
    }
    Rename-Computer -NewName $NewName -Force
    Write-Host "Computer renamed to $NewName" -ForegroundColor Green
}

function Set-TimeZoneUK {
    Write-host "Setting time zone to GMT Standard Time..." -ForegroundColor Yellow
    # Manually set time zone to GMT Standard Time (UK)
    Set-TimeZone -Id "GMT Standard Time"
    Write-Host "Time zone set to GMT Standard Time" -ForegroundColor Green

    # Enable location services
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 1

    # Set Time Zone to Automatic
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name "Start" -Value 3

    # Set Time Synchronization to Automatic
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -Value "NTP"
    try {
        Start-Service W32Time -ErrorAction Stop
    }
    catch {
        Write-Host "W32Time service is already running or could not be started" -ForegroundColor Yellow
    }
    Set-Service W32Time -StartupType Automatic

    Write-Host "Time synchronization set to automatic" -ForegroundColor Green
}

function Enable-RemoteDesktop {
    Write-Host "Enabling Remote Desktop..." -ForegroundColor Yellow
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Write-Host "Remote Desktop enabled" -ForegroundColor Green
}

function Install-Office {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("32", "64")]
        [string]$Architecture
    )
    $offlinePath = $env:TEMP
    $configFileName = if ($Architecture -eq "32") { "configuration32Bit.xml" } else { "configuration.xml" }
    $setupPath = "$offlinePath\setup.exe"
    $configPath = "$offlinePath\$configFileName"

    # Download setup.exe if not exists
    if (-not (Test-Path $setupPath)) {
        Write-Output "Downloading Setup.exe"
        (New-Object System.Net.WebClient).DownloadFile("https://github.com/ANDYG2988/SetupScript/raw/refs/heads/main/setup.exe", $setupPath)
        
    } else {
        Write-Output "Setup.exe Already Exists"
    }
    
    # Download configuration file if not exists
    $configUrl = "https://raw.githubusercontent.com/ANDYG2988/SetupScript/refs/heads/main/$configFileName"
    if (-not (Test-Path $configPath)) {
        Write-Output "Downloading Office $Architecture Bit Configuration"        
        (New-Object System.Net.WebClient).DownloadFile($configUrl, $configPath)
    } else {
        Write-Output "$configFileName Already Exists"
    }

    Write-Output "Installing Office 365 Apps For Business ($Architecture-bit)"
    try {
        & $setupPath /configure $configPath
        Write-Output "Office 365 Apps For Business Installed"
    } catch {
        Write-Host "Sorry there was an error installing Office 365" -ForegroundColor Red
    }
}

function Install-Office32 {
    Install-Office -Architecture "32"
}

function Install-Office64 {
    Install-Office -Architecture "64"
}

function Remove-AllOffice {
    $offlinePath = $env:TEMP
    $setupPath = "$offlinePath\setup.exe"
    $configPath = "$offlinePath\configurationUninstall.xml"

    # Download Office 365 Uninstaller
    if (-not (Test-Path $setupPath)) {
        Write-Output "Downloading Office Products Uninstaller"
        (New-Object System.Net.WebClient).DownloadFile("https://github.com/ANDYG2988/SetupScript/raw/refs/heads/main/setup.exe", $setupPath)
    }
    else {
        Write-Output "Setup.exe Already Exists"
    }

    if (-not (Test-Path $configPath)) {
        Write-Output "Downloading Office Uninstall Configuration"        
        (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/ANDYG2988/SetupScript/refs/heads/main/configurationUninstall.xml", $configPath)
    }
    else {
        Write-Output "configurationUninstall.xml Already Exists"
    }

    Write-Output "Uninstalling All Office Products"
    try {
        & $setupPath /configure $configPath
        Write-Output "Office Uninstalled"
    }
    catch {
        Write-Host "Sorry there was an error uninstalling Office" -ForegroundColor Red
    }
}

function Remove-Bloatware {
    Write-Host "Removing pre-installed apps (bloatware)..."
    $bloatware = @(
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxApp",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.People",
        "Microsoft.SkypeApp",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.BingNews",
        "Microsoft.BingWeather",
        "Microsoft.WindowsMaps",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.WindowsFeedbackHub",
        "ARP\Machine\X64\McAfee.WPS",
    	"9N7WSZGCK7M5"
    )

    foreach ($app in $bloatware) {
        Write-Host "`nRemoving $app..." -ForegroundColor Yellow
        winget uninstall --id $app --accept-source-agreements -h --force SilentlyContinue
    }

    $apps =@(
 		"McAfee® Personal Security",
 		"McAfee",
  		"McAfee LiveSafe",
  		"WebAdvisor by McAfee",
		"Amazon Alexa",
  		"Disney+",
    	"Spotify Music",
    	"Xbox TCUI",
      	"Xbox Console Companion",
		"Xbox Game Bar Plugin",
  		"Xbox Game Bar",
  		"Xbox Identity Provider",
    	"Xbox Game Speech Window",
      	"Xbox",
      	"Microsoft Solitaire Collection",
		"Netflix",
  		"Prime Video for Windows",
    	"Dropbox promotion",
    	"ExpressVPN"
	);    
	
	foreach($program in $apps){
 		Write-Host "`nUninstalling $program..." -ForegroundColor Yellow
		winget uninstall --name $program --accept-source-agreements -h --force
	}
    
    Write-Host "`nBloatware removal completed.`n" -ForegroundColor Green
}

function Install-Programs {
    Write-Output "`nInstallation of Standard Programs will begin" -ForegroundColor Yellow

    $programs = @("google.chrome", "Adobe.Acrobat.Reader.64-bit")
    
    foreach ($program in $programs) {
        Write-Output "Installing $program..."
        try {
            winget install $program -h --accept-source-agreements
        }
        catch {
            Write-Host "Failed to install $program`: $_" -ForegroundColor Red
        }
    }
    
    Install-Office64
}

function Install-SplashtopSOS {
    $destinationPath = "C:\Users\Public\Desktop\SplashtopSOS.exe"
    
    if (-not (Test-Path $destinationPath)) {
        Write-Host "`nDownloading SplashtopSOS.exe to Desktop..." -ForegroundColor Yellow
        try {
            Start-BitsTransfer -Source "https://github.com/agukbiz2988/SetupScript/raw/main/SplashtopSOS.exe" -Destination $destinationPath
            Write-Host "`nSplashtopSOS.exe downloaded successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "`nFailed to download SplashtopSOS.exe: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "`nSplashtopSOS.exe already exists on Desktop." -ForegroundColor Yellow
    }
}

function Remove-HPWolfSecurity {
    Write-Host "Checking if HP Wolf Security is installed..." -ForegroundColor Yellow
    $hpWolfInstalled = winget list --id "HP.HPWolfSecurity" --accept-source-agreements 2>&1 | Select-String "HP Wolf Security"

    if (-not $hpWolfInstalled) {
        Write-Host "HP Wolf Security is not installed. Skipping removal." -ForegroundColor Yellow
        return
    }

    try {
        Stop-Service -Name "HpWolfSecurityService" -Force -ErrorAction Stop
        Set-Service -Name "HpWolfSecurityService" -StartupType Disabled
    }
    catch {
        Write-Host "Warning: Could not stop HpWolfSecurityService: $_" -ForegroundColor Yellow
    }

    try {
        Stop-Service -Name "BrSvc" -Force -ErrorAction Stop
        Set-Service -Name "BrSvc" -StartupType Disabled
    }
    catch {
        Write-Host "Warning: Could not stop BrSvc: $_" -ForegroundColor Yellow
    }

    try {
        Stop-Service -Name "HPSureSenseService" -Force -ErrorAction Stop
        Set-Service -Name "HPSureSenseService" -StartupType Disabled
    }
    catch {
        Write-Host "Warning: Could not stop HPSureSenseService: $_" -ForegroundColor Yellow
    }

    # HP Wolf Applications to remove
    $hpWolfApps = @(
        "HP Wolf Security",
        "HP Wolf Security - Console",
        "HP Security Update Service"
    )
    # Uninstall apps
    foreach ($app in $hpWolfApps) {
        Write-Host "Uninstalling $app..." -ForegroundColor Yellow
        winget uninstall --name $app --accept-source-agreements -h --force
    }
    
    Write-Host "HP Wolf Security removal completed." -ForegroundColor Green
}



function Enable-DotNet3Point5 {
    Write-Host "Enabling .NET Framework 3.5..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All
}

# function Start-WindowsUpdate {
#     Write-Host "Checking for Windows Updates..." -ForegroundColor Yellow
#     Install-Module PSWindowsUpdate -Force
#     Import-Module PSWindowsUpdate
#     Get-WindowsUpdate -AcceptAll -Install -MicrosoftUpdate -IgnoreReboot 
# }

function Start-WindowsUpdate {
    [CmdletBinding()]
    param()

    Write-Host "Checking for Windows Updates..." -ForegroundColor Yellow

    # 1) Ensure TLS 1.2 for PowerShell Gallery / provider bootstrap
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch {
        # If this fails, carry on - but module install may fail on older systems
    } # TLS 1.2 commonly required for PSGallery interactions [1](https://learn.microsoft.com/en-us/powershell/module/packagemanagement/install-packageprovider?view=powershellget-2.x)[2](https://www.reddit.com/r/PowerShell/comments/rb6mai/prompted_to_install_nuget_package_provider_even/)

    # 2) Ensure NuGet provider is present (silently)
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false | Out-Null
    } # Non-interactive provider install guidance [3](https://winget.ragerworks.com/package/Google.Chrome)[4](https://www.codegenes.net/blog/how-do-i-install-the-nuget-provider-for-powershell-on-a-offline-machine/)

    # 3) Optional: trust PSGallery to avoid prompts about untrusted repository
    try {
        $psg = Get-PSRepository -Name PSGallery -ErrorAction Stop
        if ($psg.InstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
    } catch {
        # If PSGallery isn't registered, register defaults then trust it
        try {
            Register-PSRepository -Default -ErrorAction SilentlyContinue
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        } catch {}
    }

    # 4) Install + Import PSWindowsUpdate (silently)
    Install-Module PSWindowsUpdate -Force -Confirm:$false -Scope AllUsers
    Import-Module PSWindowsUpdate -Force

    # 5) Run updates
    Get-WindowsUpdate -AcceptAll -Install -MicrosoftUpdate -IgnoreReboot
}



function Join-Domain {
    $domainName = Read-Host "`nEnter the domain name"
    $domainUser = Read-Host "Enter the domain username (e.g., user@domain.com)"
    $domainPassword = Read-Host "Enter the domain password" -AsSecureString

    if ([string]::IsNullOrWhiteSpace($domainName) -or [string]::IsNullOrWhiteSpace($domainUser)) {
        Write-Host "Domain name or username not provided. Skipping domain join." -ForegroundColor Yellow
        return
    }

    try {
        Add-Computer -DomainName $domainName -Credential (New-Object System.Management.Automation.PSCredential($domainUser, $domainPassword)) -Force
        Write-Host "Successfully joined $domainName. A restart is required to complete the process."
    } catch {
        Write-Host "Failed to join domain. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Register-PowerSettings {
    # Set power scheme to Balanced
    Write-Host "`nSetting power scheme to Balanced..." -ForegroundColor Yellow
    powercfg /SetActive 381b4222-f694-41f0-9685-ff5bb260df2e

    Write-Host "Applying power settings..." -ForegroundColor Yellow
    Powercfg /Change monitor-timeout-ac 5
    Powercfg /Change monitor-timeout-dc 5
    Powercfg /Change standby-timeout-ac 0
    Powercfg /Change standby-timeout-dc 0
    powercfg /hibernate off

    # Enable password prompt after wake-up
    powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
    powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
    powercfg -SetActive SCHEME_CURRENT

    Write-Host "Power settings applied successfully." -ForegroundColor Green
}



function Install-WingetManual{
    # Opens Microsoft Store to Winget page
    Write-Host "`nOpening Microsoft Store to Winget page..." -ForegroundColor Yellow
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
}

function Install-WingetUpgrade{
    try{
        Write-Host "Downloading and installing Winget/App Installer" -ForegroundColor Yellow
        winget upgrade --id Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements
    }
    catch {
        Write-Host "Winget had issues installing" -BackgroundColor Red
    }
}

function Install-WingetGitHub{
    
    # Download latest App Installer from GitHub
    #Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$env:TEMP\AppInstaller.msixbundle"
    Start-BitsTransfer -Source "https://aka.ms/getwinget" -Destination "$env:TEMP\AppInstaller.msixbundle"

    # Install the package
    Add-AppxPackage -Path "$env:TEMP\AppInstaller.msixbundle"
}

function Install-WingetSource{
    #refreshes the package sources
    write-host "Refreshing Winget sources..." -ForegroundColor Yellow
    winget source update
}

function Start-WindowsUpdateManual {

    # Trigger Windows Update scan and opens Windows Update settings
    Write-Host "Starting Windows Update scan and opening Windows Update settings..." -ForegroundColor Yellow
    Start-Process "ms-settings:windowsupdate"

}

function Remove-CorruptedAppInstaller {
    # Close running processes
    Write-host "Removing Corrupted App Installer..." -ForegroundColor Yellow
    Get-Process Winget, AppInstaller -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Stop services that commonly lock WindowsApps content
    Write-Host "Stopping services that may lock WindowsApps content..." -ForegroundColor Yellow
    net stop appxsvc
    net stop clipsvc
    net stop wuauserv
    net stop bits
    
    # Take ownership and grant permissions to the App Installer folder
    Write-Host "Taking ownership and granting permissions to the App Installer folder..." -ForegroundColor Yellow
    Get-ChildItem "C:\Program Files\WindowsApps" -Directory -Filter "Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe" | ForEach-Object { takeown /F "$($_.FullName)" /A /R /D Y; icacls "$($_.FullName)" /grant administrators:F /T /C }
    
    # Remove the corrupted App Installer folder
    Write-Host "Removing the corrupted App Installer folder..." -ForegroundColor Yellow
    Get-ChildItem "C:\Program Files\WindowsApps" -Directory -Filter "Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe" | Remove-Item -Recurse -Force
}

function Set-Autoplay {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $HKCU_Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers"
    $HKLM_Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    if ($Value -eq 1) {
        Set-ItemProperty -Path $HKCU_Path -Name "DisableAutoplay" -Value 0 -Type DWord
        Set-ItemProperty -Path $HKLM_Path -Name "NoDriveTypeAutoRun" -Value 91 -Type DWord

        Write-Host "`nAutoplay has been ENABLED." -ForegroundColor Green
        Stop-Process -Name explorer -Force
    }else {
        Set-ItemProperty -Path $HKCU_Path -Name "DisableAutoplay" -Value 1 -Type DWord
        Set-ItemProperty -Path $HKLM_Path -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord

        Write-Host "`nAutoplay has been DISABLED." -ForegroundColor Green
        Stop-Process -Name explorer -Force
    }
}

function Enable-Autoplay {
    Set-Autoplay -Value 1
}

function Disable-Autoplay {
    Set-Autoplay -Value 0
}

function Set-WindowsLatestUpdates {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Value
    )

    $RegPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    $RegValueName = "IsContinuousInnovationOptedIn"
    
    $Action = if ($Value -eq 1) {"Enable"} else {"Disable"}
    $MsgColor = if ($Value -eq 1) {"Green"} else {"Red"}
    
    Write-Host "Attempting to $Action the setting..." -ForegroundColor Yellow
    
    # Ensure the registry key (container) exists before setting the value
    if (-not (Test-Path -Path $RegPath)) {
        Write-Host "Registry key '$RegPath' does not exist. Creating it." -ForegroundColor Yellow
        try {
            New-Item -Path $RegPath -Force | Out-Null
        }
        catch {
            Write-Error "Failed to create registry key. Access Denied or Path Invalid."
            return
        }
    }
    
    # Set the value (REG_DWORD)
    try {
        Set-ItemProperty -Path $RegPath -Name $RegValueName -Type DWORD -Value $Value -Force
        Write-Host "SUCCESS: Setting has been set to $Value. Registry updated." -ForegroundColor $MsgColor
    }
    catch {
        Write-Error "Failed to modify registry value. Ensure you are running PowerShell as Administrator."
        Write-Error $_.Exception.Message
    }
}

function Enable-WindowsLatestUpdates {
    Set-WindowsLatestUpdates -Value 1
}

function Disable-WindowsLatestUpdates {
    Set-WindowsLatestUpdates -Value 0
}

function New-Password {

    # Define word list (you can expand this list)
    $words = @("Apple","River","Stone","Cloud","Forest","Mountain","Silver","Gold","Shadow","Light","Sky","Ocean","Fire","Wind","Star","Moon","Sun","Tree","Leaf",`
                "Flower","Bird","Wolf","Lion","Tiger","Bear","Fox","Horse","Dragon","Phoenix","Eagle","Dolphin","Shark","Whale",`
                "Rain","Snow","Thunder","Lightning","Storm","Desert","Valley","Island","Canyon","Volcano","Swamp","Beach","Cliff","Hill")

    # Define special characters
    $specialChars = @("!","@","#","$","%","*")

    # Pick 2 random words
    $randomWords = (Get-Random -InputObject $words -Count 2) -join ""

    # Pick 2 random digits
    $randomDigits = -join ((0..9) | Get-Random -Count 2)

    # Pick 1 random special character
    $randomSpecial = Get-Random -InputObject $specialChars

    # Combine to form password
    $password = "$randomWords$randomDigits$randomSpecial"

    if ($password.Length -lt 12) {
        # If password is less than 12 characters, add more random words until it reaches 12 characters
        while ($password.Length -lt 12) {
            $password += Get-Random -InputObject $words
        }
    }

    Write-Host "Generated Password:`n" -ForegroundColor Yellow
    Write-Host $password -ForegroundColor Green
}


function Set-PasswordPolicy{
    param(
        [Int]$policy,
        [Int]$num
    )

    switch($policy){
        1{ Net Accounts /MINPWLEN:$num         }
        2{ Net Accounts /MINPWAGE:$num         }
        3{ Net Accounts /MAXPWAGE:$num         }
        4{ Net Accounts /UNIQUEPW:$num         }
        5{ Net accounts /lockoutthreshold:$num }
        6{ Net Accounts /lockoutduration:$num  }
        7{ Net Accounts /lockoutwindow:$num    }
    }
}

function Set-PasswordComplexity{
    param(
        [Int] $num
    )

    secedit.exe /export /cfg C:\secconfig.cfg
    Start-Sleep 1

    switch($num){
        0{
            #Disable Complexity
            (Get-Content -path C:\secconfig.cfg -Raw) -replace 'PasswordComplexity = 1', 'PasswordComplexity = 0' | Out-File -FilePath C:\secconfig.cfg
            Start-Sleep 1
        }
        1{
            #Enable Complexity
            (Get-Content -path C:\secconfig.cfg -Raw) -replace 'PasswordComplexity = 0', 'PasswordComplexity = 1' | Out-File -FilePath C:\secconfig.cfg
            Start-Sleep 1
        }
        default{Write-Host $incorrectNum}
    }
    secedit.exe /configure /db $env:windir\securitynew.sdb /cfg C:\secconfig.cfg /areas SECURITYPOLICY
}

function Set-AdministratorLockout{
    param(
        [Int] $num
    )

    secedit.exe /export /cfg C:\secconfig.cfg
    Start-Sleep 1

    switch($num){
        0{
            #Disable Admin Lockout
            (Get-Content -path C:\secconfig.cfg -Raw) -replace 'AllowAdministratorLockout = 1', 'AllowAdministratorLockout = 0' | Out-File -FilePath C:\secconfig.cfg
            Start-Sleep 1
        }
        1{
            #Enable Admin Lockout
            (Get-Content -path C:\secconfig.cfg -Raw) -replace 'AllowAdministratorLockout = 0', 'AllowAdministratorLockout = 1' | Out-File -FilePath C:\secconfig.cfg
            Start-Sleep 1
        }
        default{Write-Host $incorrectNum}
    }
    secedit.exe /configure /db $env:windir\securitynew.sdb /cfg C:\secconfig.cfg /areas SECURITYPOLICY
}

function Set-DefaultPasswordPolicy{

    #Enable/Disable Password Complexity
    Write-Host "Turning Complexity Off " -ForegroundColor green
    Set-PasswordComplexity 0
    Write-Host "Complextity Turned off`n" -ForegroundColor green
    Start-Sleep 1

    #Enable/Disable Administrator Account Lockout
    Write-Host "Disabling Admin Lockout" -ForegroundColor green
    Set-AdministratorLockout 0
    Write-Host "Completed Disabling Admin Lockout`n" -ForegroundColor green
    Start-Sleep 1

    #Change Minimum Password Length
    Write-Host "Changing Minimum Password Length Back to Default" -ForegroundColor green
    Set-PasswordPolicy -policy 1 -num 0
    Start-Sleep 1

    #Change Minimum Password Age
    Write-Host "Changing Minimum Password Age Back to Default" -ForegroundColor green
    Set-PasswordPolicy -policy 2 -num 0
    Start-Sleep 1

    #Change Maximum Password Age
    Write-Host "Changing Maximum Password Age Back to Default" -ForegroundColor green
    Set-PasswordPolicy -policy 3 -num 42
    Start-Sleep 1

    #Change Password History Size
    Write-Host "Changing Password History Size Back to Default" -ForegroundColor green
    Set-PasswordPolicy -policy 4 -num 0
    Start-Sleep 1

    #Change Lockout Threshold
    Write-Host "Changing Lockout Threshold Back to Default" -ForegroundColor green
    Set-PasswordPolicy -policy 5 -num 10
    Start-Sleep 1

    #Change Lockout Duration Time
    Write-Host "Changing Lockout Duration Time Back to Default" -ForegroundColor green
    Set-PasswordPolicy -policy 7 -num 10
    Start-Sleep 1

    #Change Lockout Window Time
    Write-Host "Changing Lockout Window Time Back to Default" -ForegroundColor green
    Set-PasswordPolicy -policy 6 -num 10
    Start-Sleep 1

    net accounts
}

function Set-RecommendedPasswordPolicy{

    #Enable/Disable Password Complexity
    Write-Host "Turning Complexity On " -ForegroundColor green
    Set-PasswordComplexity 1
    Write-Host "Complextity Turned On`n" -ForegroundColor green
    Start-Sleep 1

    #Enable/Disable Administrator Account Lockout
    Write-Host "Enabling Admin Lockout" -ForegroundColor green
    Set-AdministratorLockout 1
    Write-Host "Completed Enabling Admin Lockout`n" -ForegroundColor green
    Start-Sleep 1

    #Change Minimum Password Length
    Write-Host "Changing Minimum Password Length to Recommended Setting" -ForegroundColor green
    Set-PasswordPolicy -policy 1 -num 12
    Start-Sleep 1

    #Change Minimum Password Age
    Write-Host "Changing Minimum Password Age to Recommended Setting" -ForegroundColor green
    Set-PasswordPolicy -policy 2 -num 0
    Start-Sleep 1

    #Change Maximum Password Age
    Write-Host "Changing Maximum Password Age to Recommended Setting" -ForegroundColor green
    Net Accounts /MAXPWAGE:UNLIMITED
    Start-Sleep 1

    #Change Password History Size
    Write-Host "Changing Password History Size to Recommended Setting" -ForegroundColor green
    Set-PasswordPolicy -policy 4 -num 24
    Start-Sleep 1

    #Change Lockout Threshold
    Write-Host "Changing Lockout Threshold to Recommended Setting" -ForegroundColor green
    Set-PasswordPolicy -policy 5 -num 10
    Start-Sleep 1

    #Change Lockout Window Time
    Write-Host "Changing Lockout Window Time to Recommended Setting" -ForegroundColor green
    Set-PasswordPolicy -policy 6 -num 30
    Start-Sleep 1

    #Change Lockout Duration Time
    Write-Host "Changing Lockout Duration Time to Recommended Setting" -ForegroundColor green
    Set-PasswordPolicy -policy 7 -num 30
    Start-Sleep 1

    net accounts
}

function Disable-Widgets {
    try {
        # Disable Widgets via Registry
        winget uninstall --id "9MSSGKG348SP"

        Write-Host "Widgets have been disabled successfully."
    }
    catch {
        Write-Host "Failed to disable Widgets: $_"
    }
}

function Disable-TaskView {
    try {
        # Disable Task View button
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

        Write-Host "Task View has been disabled successfully."
    }
    catch {
        Write-Host "Failed to disable Task View: $_"
    }
}


function Set-PerformanceSettingsLocal {
    
    # Set to Custom
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
        -Name VisualFXSetting -Value 3
    
    # ENABLE EFFECTS
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name IconsOnly -Value 0
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ListviewAlphaSelect -Value 1
    Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name DragFullWindows -Value 1
    Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name FontSmoothing -Value "2"
    
    # DISABLE ALL OTHER EFFECTS
    # This mask disables animations, fades, shadows, slide combo boxes, smooth scroll, etc.
    Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name UserPreferencesMask -Type Binary `
        -Value (0x90,0x12,0x01,0x80,0x10,0x00,0x00,0x00)
    
    # Disable min/max animations
    Set-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" -Name MinAnimate -Value 0
    
    # Disable taskbar animations
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAnimations -Value 0
    
    # Disable shadows and peek
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\DWM" -Name EnableAeroPeek -Value 0
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\DWM" -Name AlwaysHibernateThumbnails -Value 0
    
    # Disable icon label shadows
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ListviewShadow -Value 0
    
    # Disable transparency
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0
    
    # Disable Game Mode
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0
    
}

function Disable-EdgeStartUp {

    Write-Host "Disabling Edge First Run Experience..." -ForegroundColor Yellow

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DisableFirstRunExperience" -Value 1 -Type DWord
}

function Disable-ChromeStartUp {

    Write-Host "Disabling Chrome First Run Experience..." -ForegroundColor Yellow

    New-Item -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Force | Out-Null
    #Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "BrowserSignin" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "SyncDisabled" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "DefaultBrowserSettingEnabled" -Value 0 -Type DWord
}

function Start-NewComputerSetup {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   STARTING NEW COMPUTER SETUP" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    $setupChoice = Read-Host "Do you want to select different options before running this script (Y/N)"
    while ($setupChoice -notmatch '^[YNyn]$') {
        Write-Host "Invalid input. Please enter Y or N." -ForegroundColor Red
    }

    if ($setupChoice -eq "Y" -or $setupChoice -eq "y") {
        $dotNetChoice = Read-Host "Do you want to enable .NET Framework 3.5? (Y/N)"
        while ($dotNetChoice -notmatch '^[YNyn]$') {Write-Host "Invalid input. Please enter Y or N." -ForegroundColor Red}
        
        $passwordPolicyChoice = Read-Host "Do you want to set Recommended Password Policy? (Y/N)"
        while ($passwordPolicyChoice -notmatch '^[YNyn]$') {Write-Host "Invalid input. Please enter Y or N." -ForegroundColor Red}

    } else {
        Write-Host "All functions will run with default options..."
    }

        Write-Host "[1/18] Registering Power Settings..." -ForegroundColor Yellow
        Register-PowerSettings

        Write-Host "`n[2/18] Disabling Edge Startup..." -ForegroundColor Yellow
        Disable-EdgeStartUp
        
        Write-Host "`n[3/18] Installing Splashtop SOS..." -ForegroundColor Yellow
        Install-SplashtopSOS
        
        Write-Host "`n[4/18] Updating All Packages..." -ForegroundColor Yellow
        Update-AllPackages
        
        Write-Host "`n[5/18] Setting TimeZone to UK..." -ForegroundColor Yellow
        Set-TimeZoneUK
        
        Write-Host "`n[6/18] Enabling Remote Desktop..." -ForegroundColor Yellow
        Enable-RemoteDesktop
        
        Write-Host "`n[7/18] Removing Bloatware..." -ForegroundColor Yellow
        Remove-Bloatware
        
        if ($dotNetChoice -eq "Y" -or $dotNetChoice -eq "y") {
            Write-Host "`n[8/18] Enabling .NET Framework 3.5...(Please note this can take a while)" -ForegroundColor Yellow
            Enable-DotNet3Point5
        } else {
            Write-Host "Skipping .NET Framework 3.5 installation." -ForegroundColor Yellow
        }
        
        Write-Host "`n[9/18] Removing HP Wolf Security..." -ForegroundColor Yellow
        Remove-HPWolfSecurity
        
        Write-Host "`n[10/18] Setting Performance Settings Local..." -ForegroundColor Yellow
        Set-PerformanceSettingsLocal

        Write-Host "`n[11/18] Disabling Widgets..." -ForegroundColor Yellow
        Disable-Widgets

        Write-Host "`n[12/18] Disabling Task View..." -ForegroundColor Yellow
        Disable-TaskView

        Write-Host "`n[13/18] Disabling Autoplay..." -ForegroundColor Yellow
        Disable-Autoplay

        if ($passwordPolicyChoice -eq "Y" -or $passwordPolicyChoice -eq "y") {
            Write-Host "`n[14/18] Setting Recommended Password Policy..." -ForegroundColor Yellow
            Set-RecommendedPasswordPolicy
        } else {
            Write-Host "Skipping Recommended Password Policy - (Staying on Default)" -ForegroundColor Yellow
        }

        Write-Host "`n[15/18] Enabling Windows Latest Updates..." -ForegroundColor Yellow
        Enable-WindowsLatestUpdates

        Write-Host "`n[16/18] Installing Programs..." -ForegroundColor Yellow
        Install-Programs

        Write-Host "`n[17/18] Disabling Chrome Startup..." -ForegroundColor Yellow
        Disable-ChromeStartUp
        
        Write-Host "`n[18/18] Starting Windows Update...(Please note this can take a while)" -ForegroundColor Yellow
        Start-WindowsUpdate

        Write-Host "`nNew Computer Setup completed. Please review the above steps for any errors." -ForegroundColor Green

        Write-Host "`nStopping Explorer to apply some changes..." -ForegroundColor Yellow
        Stop-Explorer 
        
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "   SETUP COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    $restartChoice = Read-Host "Do you want to restart your computer now to apply all changes? (Y/N)"
    if ($restartChoice -eq "Y" -or $restartChoice -eq "y") {
        Restart-Computer
    } else {
        Write-Host "Please restart your computer manually to apply all changes." -ForegroundColor Cyan
    }
}

function Stop-Explorer {
    Stop-Process -Name explorer -Force
}

function Restart-LocalComputer {
    Write-Host "Restarting computer in 10 seconds. Press Ctrl+C to cancel..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Start-Process "shutdown.exe" -ArgumentList "/r /f /t 0" -Verb RunAs
}

# ---------------- EXECUTION ---------------- ##

clear-host
$menuLoop = $true

while ($menuLoop) {
Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "         SETUP SCRIPT MAIN MENU         " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[Automation]" -ForegroundColor Yellow
Write-Host "[*] Start New Computer Setup (Automated)" -ForegroundColor Green

Write-Host "`n[Core Setup]" -ForegroundColor Yellow
Write-Host "  [ 1] Update All Packages"
Write-Host "  [ 2] Rename PC"
Write-Host "  [ 3] Set TimeZone to UK"
Write-Host "  [ 4] Enable Remote Desktop"
Write-Host "  [ 5] Remove Bloatware"
Write-Host "  [ 6] Install Programs"
Write-Host "  [ 7] Enable .NET Framework 3.5"
Write-Host "  [ 8] Start Windows Update (Auto)"
Write-Host "  [ 9] Start Windows Update (Manual)"
Write-Host "  [10] Join Domain"

Write-Host "`n[Office / Apps]" -ForegroundColor Yellow
Write-Host "  [11] Install Office 32-bit"
Write-Host "  [12] Install Office 64-bit"
Write-Host "  [13] Uninstall All Office Products"
Write-Host "  [14] Install Splashtop SOS"
Write-Host "  [15] Remove HP Wolf Security"

Write-Host "`n[Winget / App Installer]" -ForegroundColor Yellow
Write-Host "  [16] Install Winget Source"
Write-Host "  [17] Install Winget from GitHub"
Write-Host "  [18] Upgrade Winget"
Write-Host "  [19] Install Winget Manual"
Write-Host "  [20] Remove Corrupted App Installer"

Write-Host "`n[UI / UX Tweaks]" -ForegroundColor Yellow
Write-Host "  [21] Disable Widgets"
Write-Host "  [22] Disable Task View"
Write-Host "  [23] Enable Autoplay"
Write-Host "  [24] Disable Autoplay"
Write-Host "  [25] Disable Edge Startup"
Write-Host "  [26] Disable Chrome Startup"
Write-Host "  [27] Stop Explorer"

Write-Host "`n[Performance / Power]" -ForegroundColor Yellow
Write-Host "  [28] Register Power Settings"
Write-Host "  [29] Set Performance Settings"
Write-Host "  [30] Restart Computer"

Write-Host "`n[Security / Passwords]" -ForegroundColor Yellow
Write-Host "  [31] Generate New Password"
Write-Host "  [32] Set Recommended Password Policy"
Write-Host "  [33] Set Default Password Policy"

Write-Host "`n  [ 0] Exit" -ForegroundColor Red

    $choice = Read-Host "Enter your selection"

    switch ($choice) {
        "*"  { Start-NewComputerSetup }
        "1"  { Update-AllPackages }
        "2"  { Rename-PC }
        "3"  { Set-TimeZoneUK }
        "4"  { Enable-RemoteDesktop }
        "5"  { Remove-Bloatware }
        "6"  { Install-Programs }
        "7"  { Enable-DotNet3Point5 }
        "8"  { Start-WindowsUpdate }
        "9"  { Start-WindowsUpdateManual }
        "10" { Join-Domain }
        "11" { Install-Office64 }
        "12" { Install-Office32 }
        "13" { Remove-AllOffice}
        "14" { Install-SplashtopSOS }
        "15" { remove-HPWolfSecurity }
        "16" { Install-WingetSource }
        "17" { Install-WingetGitHub }
        "18" { Install-WingetUpgrade }
        "19" { Install-WingetManual }
        "20" { Remove-CorruptedAppInstaller }
        "21" { Disable-Widgets }
        "22" { Disable-TaskView }
        "23" { Enable-Autoplay }
        "24" { Disable-Autoplay }
        "25" { Disable-EdgeStartUp }
        "26" { Disable-ChromeStartUp }
        "27" { Stop-Explorer }
        "28" { Register-PowerSettings }
        "29" { Set-PerformanceSettings }
        "30" { Restart-LocalComputer }
        "31" { New-Password }
        "32" { Set-RecommendedPasswordPolicy }
        "33" { Set-DefaultPasswordPolicy }
        "0"  { $menuLoop = $false; Write-Host "`nExiting script." -ForegroundColor Yellow }
        default { Write-Host "Invalid selection. Please try again." -ForegroundColor Red }
    }
}
[Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
