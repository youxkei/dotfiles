komorebic stop --whkd

function Get-MonitorCount {
    (Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue).Count
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$komorebiScript = Join-Path $scriptDir "komorebi.ps1"

Write-Host "Starting komorebi..."
& $komorebiScript

$prevCount = Get-MonitorCount
Write-Host "Monitoring started: current monitor count = $prevCount"

while ($true) {
    Start-Sleep -Seconds 2
    $currentCount = Get-MonitorCount

    if ($currentCount -ne $prevCount) {
        Write-Host "Monitor count changed ($prevCount -> $currentCount), restarting komorebi..."
        komorebic stop --whkd
        Start-Sleep -Seconds 2
        & $komorebiScript
        $prevCount = $currentCount
    }
}
