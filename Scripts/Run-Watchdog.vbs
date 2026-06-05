Set objShell = CreateObject("Wscript.Shell")
objShell.Run """C:\Program Files\PowerShell\7\pwsh.exe"" -ExecutionPolicy Bypass -File ""C:\TargetTech\Scripts\Watchdog-SwitchLauncher.ps1""", 0, False