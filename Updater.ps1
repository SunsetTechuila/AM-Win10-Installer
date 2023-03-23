#Requires -RunAsAdministrator
#Requires -PSEdition Desktop

$ErrorActionPreference = "Stop"

#region Get MSIX bundle link
$Parameters = @{
    Uri             = "https://store.rg-adguard.net/api/GetFiles"
    UseBasicParsing = $true
    Method          = "POST"
    Body            = @{
        type = "ProductId"
        url  = "9PFHDD62MXS1"
        ring = "Fast"
    }
}
$msixBundleLink = (Invoke-WebRequest @Parameters).Links | Where-Object { $_.outerHTML -like "*AppleInc*msixbundle*" }
#endregion Get MSIX bundle link

#region Get versions
$installedVersion = (Get-AppxPackage AppleInc.AppleMusic*).Version

$msixBundleLink.outerHTML -match 'AppleMusicWin_(.+)_neutral' | Out-Null
if ($matches) {
    $latestVersion = $matches[1]
}
else {
    exit
}
#endregion Get versions

#region Compare versions
if ($latestVersion -gt $installedVersion) {
    $Parameters = @{
        FilePath = "powershell"
        ArgumentList = "-ExecutionPolicy Bypass -WindowStyle Hidden -File $Env:LOCALAPPDATA\AM-Win10-Installer\Installer.ps1 -SkipAMCheck"
        Verb = "RunAs"
    }
    Start-Process @Parameters
    exit
}
#endregion Compare versions