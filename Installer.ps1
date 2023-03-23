#Requires -RunAsAdministrator
#Requires -PSEdition Desktop

#region Misc
$ErrorActionPreference = "Stop"
[Console]::Title = "Apple Music Win10 Installer"
#endregion Misc

#region Check Apple Music installation
if (Get-AppxPackage AppleInc.AppleMusic*) {
    Throw "Apple Music is already installed!"
}
#endregion Check Apple Music installation

#region Enable Developer mode
Write-Verbose -Message "Enabling Developer mode..." -Verbose

New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -PropertyType DWORD -Force | Out-Null
#endregion Enable Developer mode

#region Dependencies

#region Windows App Runtime 1.2
$appxPackage = Get-AppxPackage Microsoft.WindowsAppRuntime* | Where-Object -Property Architecture -EQ "X64"
$versions = @()

$appxPackage.PackageFullName | ForEach-Object { 
    $PSItem -match 'Microsoft\.WindowsAppRuntime\.(.{3}).+' | Out-Null
    if ($matches) {
        $versions += $matches[1]
    }
}

$installed = $false
$versions | ForEach-Object { 
    if ($PSItem -ge 1.2) {
        $installed = $true
        return
    }
}

if (-not ($installed)) {
    Write-Verbose -Message "Downloading Windows App Runtime 1.2..." -Verbose

    $Parameters = @{
        Uri             = "https://aka.ms/windowsappsdk/1.2/latest/windowsappruntimeinstall-x64.exe"
        UseBasicParsing = $true
        OutFile         = "$Env:TEMP\windowsappruntimeinstall-x64.exe"
    }
    Invoke-WebRequest @Parameters

    Write-Verbose -Message "Installing Windows App Runtime 1.2..." -Verbose
    ."$Env:TEMP\windowsappruntimeinstall-x64.exe"
}
#endregion Windows App Runtime 1.2

#region VCLibs
$vcLibs = Get-AppxPackage Microsoft.VCLibs.140.00 | Where-Object -Property Architecture -EQ "X64"
$vcLibsUwp = Get-AppxPackage Microsoft.VCLibs.140.00.UWPDesktop | Where-Object -Property Architecture -EQ "X64"

if (($vcLibs -and $vcLibsUwp) -ne $true) {
    $Parameters = @{
        Uri             = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        UseBasicParsing = $true
        OutFile         = "$Env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"
    }
    Invoke-WebRequest @Parameters

    Write-Verbose -Message "Installing VCLibs..." -Verbose
    ."$Env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"
}
#endregion VCLibs

#endregion Dependencies

#region Get MSIX bundle link
Write-Verbose -Message "Getting latest Apple Music MSIX link..." -Verbose

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
$msixBundleLink = ( (Invoke-WebRequest @Parameters).Links | Where-Object { $_.outerHTML -like "*AppleInc*msixbundle*" } ).href
#endregion Get MSIX link

#region Apple Music download
Write-Verbose -Message "Downloading Apple Music..." -Verbose

$Parameters = @{
    Uri             = $msixBundleLink
    UseBasicParsing = $true
    OutFile         = "$Env:TEMP\AppleMusic.zip"
}
Invoke-WebRequest @Parameters
#endregion Apple Music download

#region Apple Music unpack
Write-Verbose -Message "Unpacking Apple Music..." -Verbose

Remove-Item -Path $Env:TEMP\AppleMusic -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item -Path $Env:LOCALAPPDATA\AppleMusic -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

Expand-Archive -Path $Env:TEMP\AppleMusic.zip -DestinationPath $Env:TEMP\AppleMusic
$msixPackage = Get-ChildItem -Path $Env:TEMP\AppleMusic | Where-Object Extension -EQ ".msix"
$msixArchive = @{
    Name     = $msixPackage.BaseName + ".zip"
    FullName = $msixPackage.FullName -replace ".msix", ".zip"
}
Rename-Item -Path $msixPackage.FullName -NewName $msixArchive.Name
Expand-Archive -Path $msixArchive.FullName -DestinationPath $Env:LOCALAPPDATA\AppleMusic
#endregion Apple Music unpack

#region Apple Music patch
Write-Verbose -Message "Patching Apple Music..." -Verbose

$windowsBuild = ([System.Environment]::OSVersion.Version).Build

[xml]$manifest = Get-Content -Path $Env:LOCALAPPDATA\AppleMusic\AppxManifest.xml

$xmlNamespaceManager = New-Object System.Xml.XmlNamespaceManager($manifest.NameTable)
$xmlNamespaceManager.AddNamespace("ns", "http://schemas.microsoft.com/appx/manifest/foundation/windows10")

$targetDeviceFamily = $manifest.SelectSingleNode("//ns:TargetDeviceFamily", $xmlNamespaceManager)
$targetDeviceFamily.SetAttribute("MinVersion", "10.0.$windowsBuild.0")

$manifest.Save("$Env:LOCALAPPDATA\AppleMusic\AppxManifest.xml")

Remove-Item -Path $Env:LOCALAPPDATA\AppleMusic\AppxSignature.p7x, $Env:LOCALAPPDATA\AppleMusic\AppxBlockMap.xml, $Env:LOCALAPPDATA\AppleMusic\AppxMetadata -Recurse -Force
#endregion Apple Music patch

#region Apple Music install
Write-Verbose -Message "Installing Apple Music..." -Verbose

Add-AppxPackage -Register $Env:LOCALAPPDATA\AppleMusic\AppxManifest.xml
#endregion Apple Music install

#region Clean Up
Write-Verbose -Message "Cleaning Up..." -Verbose

Remove-Item -Path $Env:TEMP\windowsappruntimeinstall-x64.exe, $Env:TEMP\AppleMusic.zip, $Env:TEMP\AppleMusic -Recurse -Force -ErrorAction SilentlyContinue
#endregion Clean Up

#region Final message
Clear-Host
Write-Host
Write-Host -Object "All operations have been completed successfuly!" -ForegroundColor Green
Write-Host
Write-Host -Object "Glad you like the script. If so - do not forget to give a star: https://github.com/SunsetTechuila/AM-Win10-Installer"
Start-Sleep -Seconds 3
#endregion Final message
