Start-Job -ScriptBlock {
    kill -Name carla

    $process = Start-Process -PassThru -FilePath "P:\software\Carla\Carla.exe" -ArgumentList "P:\carla\patch_windows_totalmix.carxp"
    $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::AboveNormal
}
