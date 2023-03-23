$ErrorActionPreference = "Stop"

#region Cleaning
Remove-Item -Path $Env:LOCALAPPDATA\AM-Win10-Installer -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $Env:LOCALAPPDATA\AM-Win10-Installer -ItemType Directory | Out-Null
#endregion Cleaning

#region Installer
Write-Verbose -Message "Downloading Installer..." -Verbose

$Parameters = @{
    Uri             = "https://raw.githubusercontent.com/SunsetTechuila/AM-Win10-Installer/main/Installer.ps1"
    UseBasicParsing = $true
    OutFile         = "$Env:LOCALAPPDATA\AM-Win10-Installer\Installer.ps1"
}
Invoke-WebRequest @Parameters
#endregion Installer

#region Updater
Write-Host -Object "Updates via Microsoft Store won't avalible"
$choice = $host.UI.PromptForChoice("", "Do you want to install auto updater for Apple Music?", ("&Yes", "&No"), 0)
if ($choice -eq 0) {
    Write-Verbose -Message "Downloading Updater..." -Verbose

    $Parameters = @{
        Uri             = "https://raw.githubusercontent.com/SunsetTechuila/AM-Win10-Installer/main/Updater.ps1"
        UseBasicParsing = $true
        OutFile         = "$Env:LOCALAPPDATA\AM-Win10-Installer\Updater.ps1"
    }
    Invoke-WebRequest @Parameters

    #region Updater task 
    $name = 'AM Updater'
    $action = New-ScheduledTaskAction -Execute powershell.exe -Argument ("-ExecutionPolicy Bypass -File $Env:LOCALAPPDATA\AM-Win10-Installer\Updater.ps1")
    $user = whoami
    $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Monday -At 12am
    $description = "Update Apple Music once a week"
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
    $scriptblock = {
        $ErrorActionPreference = "Stop"
        Stop-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        Register-ScheduledTask -TaskName $name -Description $description -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null
        Start-Sleep -Seconds 1
        Start-ScheduledTask -TaskName $name
        exit
    }
    $Parameters = @{
        FilePath     = "powershell"
        ArgumentList = "-ExecutionPolicy Bypass -WindowStyle Hidden -Сommand &{$scriptBlock}"
        Verb         = "RunAs"
    }
    Write-Verbose -Message "Registering Updater task..." -Verbose
    Start-Process @Parameters
    #endregion Updater task 
}
#endregion Updater

Start-Process -FilePath powershell -ArgumentList "-ExecutionPolicy Bypass -File $Env:LOCALAPPDATA\AM-Win10-Installer\Installer.ps1" -Verb RunAs

exit
