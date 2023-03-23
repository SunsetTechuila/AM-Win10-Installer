# Apple Music Win10 Installer

## How to

Run PowerShell as Administrator, paste this commands and press Enter.

```powershell
powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
IWR -UseB "https://raw.githubusercontent.com/SunsetTechuila/AM-Win10-Installer/main/Installer.ps1" | IEX
```
