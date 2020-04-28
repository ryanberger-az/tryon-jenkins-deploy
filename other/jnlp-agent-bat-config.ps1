# Enable Developer Mode
# Create AppModelUnlock if it doesn't exist, required for enabling Developer Mode
$RegistryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not(Test-Path -Path $RegistryKeyPath)) {
    New-Item -Path $RegistryKeyPath -ItemType Directory -Force
}
# Add registry value to enable Developer Mode
New-ItemProperty -Path $RegistryKeyPath -Name AllowDevelopmentWithoutDevLicense -PropertyType DWORD -Value 1

# Configure Autologon
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$DefaultUsername = "agentadmin"
$DefaultPassword = "CycleCI25@2019f!7Fzg!2"
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty $RegPath "DefaultUsername" -Value "$DefaultUsername" -type String 
Set-ItemProperty $RegPath "DefaultPassword" -Value "$DefaultPassword" -type String
reg.exe ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Windows /v NoInteractiveServices /t REG_DWORD /d 0 /f

# Download and Install Java
Set-ExecutionPolicy Unrestricted -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Default workspace location
Set-Location C:\
$source = "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-windows-x64.exe"
$destination = "C:\jdk-8u131-windows-x64.exe"
$client = new-object System.Net.WebClient
$cookie = "oraclelicense=accept-securebackup-cookie"
$client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
$client.downloadFile($source, $destination)
$proc = Start-Process -FilePath $destination -ArgumentList "/s" -Wait -PassThru
$proc.WaitForExit()
$javaHome = "c:\Program Files\Java\jdk1.8.0_131"
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", ${javaHome}, "Machine")
[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";${javaHome}\bin", "Machine")
$Env:Path += ";${javaHome}\bin"

# Install Git
$source = "https://github.com/git-for-windows/git/releases/latest"
$latestRelease = Invoke-WebRequest -UseBasicParsing $source -Headers @{"Accept"="application/json"}
$json = $latestRelease.Content | ConvertFrom-Json
$latestVersion = $json.tag_name
$versionHead = $latestVersion.Substring(1, $latestVersion.IndexOf("windows")-2)
$source = "https://github.com/git-for-windows/git/releases/download/v${versionHead}.windows.1/Git-${versionHead}-64-bit.exe"
$destination = "C:\Git-${versionHead}-64-bit.exe"
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($source, $destination)
$proc = Start-Process -FilePath $destination -ArgumentList "/VERYSILENT" -Wait -PassThru
$proc.WaitForExit()
$Env:Path += ";C:\Program Files\Git\cmd"
#Disable git credential manager, get more details in https://support.cloudbees.com/hc/en-us/articles/221046888-Build-Hang-or-Fail-with-Git-for-Windows
git config --system --unset credential.helper

# Install Chocolatey, Chrome, and UltraVNC Server
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install ultravnc --y --ignore-checksums
choco install googlechrome --y --ignore-checksums
choco install selenium-all-drivers --y --ignore-checksums

# Install Slaves jar and connect via JNLP
# Jenkins plugin will dynamically pass the server name and vm name.
# If your jenkins server is configured for security , make sure to edit command for how slave executes
$jenkinsserverurl = $args[0]
$vmname = $args[1]
$secret = $args[2]

# Downloading jenkins slaves jar
Write-Output "Downloading jenkins slave jar "
mkdir c:\jenkins
$slaveSource = $jenkinsserverurl + "jnlpJars/slave.jar"
$destSource = "c:\jenkins\slave.jar"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($slaveSource, $destSource)

# Download the bat boilerplate
$batConfigFile = "c:\jenkins\jenkins-slave.bat"
$wc.DownloadFile("https://raw.githubusercontent.com/ryanberger-az/tryon-jenkins-deploy/master/other/jenkins-slave.bat", $batConfigFile)


# Prepare bat file config
Write-Output "Executing agent process "
$batConfigExec = "${javaHome}\bin\java.exe"
$batConfigArgs = "-jar c:\jenkins\slave.jar -jnlpUrl `"${jenkinsserverurl}/computer/${vmname}/slave-agent.jnlp`" -noReconnect"
if ($secret) {
    $batConfigArgs += " -secret `"$secret`""
}
(Get-Content $batConfigFile).replace('@JAVA@', $batConfigExec) | Set-Content $batConfigFile
(Get-Content $batConfigFile).replace('@ARGS@', $batConfigArgs) | Set-Content $batConfigFile

# Put together scheduled task to launch the Jenkins agent via bat file at user login.
$A = New-ScheduledTaskAction -Execute "c:\jenkins\jenkins-slave.bat"
$T = New-ScheduledTaskTrigger -AtLogon
$P = New-ScheduledTaskPrincipal "$env:COMPUTERNAME\agentadmin"
$S = New-ScheduledTaskSettingsSet
$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
Register-ScheduledTask T1 -InputObject $D

# Restart Temp Node
Restart-Computer
