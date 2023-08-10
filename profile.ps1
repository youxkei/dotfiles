$env:KOMOREBI_CONFIG_HOME = "$env:USERPROFILE\.config\komorebi"

Set-PSReadLineKeyHandler -Key "Ctrl+w" -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key "Ctrl+u" -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key "Ctrl+k" -Function ForwardDeleteLine
Set-PSReadLineKeyHandler -Key "Ctrl+a" -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key "Ctrl+e" -Function EndOfLine
Set-PSReadLineKeyHandler -Key "Ctrl+p" -Function PreviousHistory
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function NextHistory
