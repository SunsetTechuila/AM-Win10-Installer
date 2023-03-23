Remove-Item -Path $Env:TEMP\Installer.ps1 -Force -ErrorAction SilentlyContinue

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Parameters = @{
    Uri             = "https://raw.githubusercontent.com/SunsetTechuila/AM-Win10-Installer/main/Installer.ps1"
    UseBasicParsing = $true
    OutFile         = "$Env:TEMP\Installer.ps1"
}
Invoke-WebRequest @Parameters

Start-Process -FilePath powershell -ArgumentList "-ExecutionPolicy Bypass -File $Env:TEMP\Installer.ps1" -Verb RunAs