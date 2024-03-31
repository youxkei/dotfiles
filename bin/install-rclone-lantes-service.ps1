if (!(Test-Path C:\rclone_log)) {
    New-Item -Path C:\rclone_log -ItemType Directory
}

sudo {
    nssm install rclone_lantes (Get-Command rclone).Source mount lantes:Home L: `
        --vfs-cache-mode full `
        --vfs-cache-max-age 1M `
        --vfs-cache-max-size 200G `
        --vfs-case-insensitive `
        --vfs-fast-fingerprint `
        --file-perms "0777" `
        -o "FileSecurity=D:P(A;;FA;;;WD)" `
        --transfers 1024 `
        --dir-cache-time 10s `
        --vfs-read-chunk-size off `
        --vfs-cache-poll-interval 10s `
        --config $Env:AppData\rclone\rclone.conf `
        --cache-dir $Env:LocalAppData\rclone `
        -v `

    nssm set rclone_lantes AppStdout C:\rclone_log\lantes.txt
    nssm set rclone_lantes AppStderr C:\rclone_log\lantes.txt
    nssm set rclone_lantes AppRotateFiles 1
    nssm set rclone_lantes AppRotateOnline 1
    nssm set rclone_lantes AppRotateBytes (10 * 1024 * 1024)

    New-ItemProperty -LiteralPath "HKLM:SYSTEM\CurrentControlSet\Services\rclone_lantes\Parameters" -Name "AppRotate" -PropertyType "DWORD" -Value 1
}
