do
{
    Start-Sleep 5
    $result = Get-PNPDevice | Where-Object {($_.Status -eq "ok") -and ($_.InstanceId -eq "USB\VID_1235&PID_8217\V275QW42602F0D")}
}
while($result -eq $null)

Start-Process "C:\Program Files\JACK2\jackd.exe" -WindowStyle Hidden -ArgumentList '-S -X winmme -dportaudio -d "ASIO::ASIO Link Pro" -r48000 -p384' &

do
{
    Start-Sleep 1
    $result = Get-Process | Where-Object {$_.MainWindowTitle -match "^ASIO Link Pro"}
}
while($result -eq $null)

Start-Process -FilePath "P:\software\Carla\Carla.exe" -ArgumentList "P:\carla\patch_windows.carxp" &
