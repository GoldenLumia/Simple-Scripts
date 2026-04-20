# Turn off
# PS D:\path\to\your\folder> .\ToggleWifiRadio.ps1 -Status 'Off'

# Turn on
# PS D:\path\to\your\folder> .\ToggleWifiRadio.ps1 -Status 'On'

# Off, wait 5s, then on
# PS D:\path\to\your\folder> .\ToggleWifiRadio.ps1 -Restart

[CmdletBinding(DefaultParameterSetName='Status')] Param (
    [Parameter(ParameterSetName='Status', Mandatory=$true)][ValidateSet('Off', 'On')][string]$Status,
    [Parameter(ParameterSetName='Restart', Mandatory=$true)][switch]$Restart
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
Function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}
[Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
[Windows.Devices.Radios.RadioAccessStatus,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
Await ([Windows.Devices.Radios.Radio]::RequestAccessAsync()) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
$radios = Await ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
$wifiRadio = $radios | ? { $_.Kind -eq 'WiFi' }
[Windows.Devices.Radios.RadioState,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
if ($Restart) {
    Await ($wifiRadio.SetStateAsync('Off')) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
    Start-Sleep -Seconds 5
    Await ($wifiRadio.SetStateAsync('On')) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
} else {
    Await ($wifiRadio.SetStateAsync($Status)) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
}