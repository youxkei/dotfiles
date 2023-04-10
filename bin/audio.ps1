Start-Process -FilePath "C:\Program Files\JACK2\qjackctl\qjackctl.exe" &
Start-Sleep -s 20
Start-Process -FilePath "P:\software\Carla\Carla.exe" -ArgumentList "P:\carla\patch_windows.carxp" &
