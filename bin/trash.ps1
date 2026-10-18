# Sends each path given to the Recycle Bin, for bin/trash.
param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Paths)
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName Microsoft.VisualBasic
foreach ($p in $Paths) {
    if (Test-Path -LiteralPath $p -PathType Container) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($p, 'OnlyErrorDialogs', 'SendToRecycleBin')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($p, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
}
