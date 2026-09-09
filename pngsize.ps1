Add-Type -AssemblyName System.Drawing
Get-ChildItem 'C:\Users\ash72\Documents\文明\art\soidler\*.png' | ForEach-Object { $img = [System.Drawing.Image]::FromFile($_.FullName); Write-Output ($_.Name + ' = ' + $img.Width + 'x' + $img.Height); $img.Dispose() }
