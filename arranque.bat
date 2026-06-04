@echo off
:: 1. Copia este mismo archivo a la carpeta de inicio para que se ejecute solo al prender la PC
copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\" /y

:: 2. Crea el script de fondo que habla con Firebase de forma invisible
echo $BaseURL = "https://apagadoautomatico-default-rtdb.firebaseio.com" > %TEMP%\script.ps1
echo $PC_ID = $env:COMPUTERNAME >> %TEMP%\script.ps1
echo while ($true) { >> %TEMP%\script.ps1
echo     $Timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds() >> %TEMP%\script.ps1
echo     $StatusData = @{ ultimaConexion = $Timestamp } ^| ConvertTo-Json >> %TEMP%\script.ps1
echo     Invoke-RestMethod -Uri "$BaseURL/computadoras/$PC_ID.json?x-http-method-override=PATCH" -Method Post -Body $StatusData -ContentType "application/json" ^> $null >> %TEMP%\script.ps1
echo     try { >> %TEMP%\script.ps1
echo         $ComandoIndividual = Invoke-RestMethod -Uri "$BaseURL/computadoras/$PC_ID/comando.json" -Method Get >> %TEMP%\script.ps1
echo         if ($ComandoIndividual -eq "shutdown") { >> %TEMP%\script.ps1
echo             Invoke-RestMethod -Uri "$BaseURL/computadoras/$PC_ID/comando.json" -Method Delete ^> $null >> %TEMP%\script.ps1
echo             stop-computer -force >> %TEMP%\script.ps1
echo         } >> %TEMP%\script.ps1
echo     } catch {} >> %TEMP%\script.ps1
echo     try { >> %TEMP%\script.ps1
echo         $ComandoGlobal = Invoke-RestMethod -Uri "$BaseURL/comando_global.json" -Method Get >> %TEMP%\script.ps1
echo         if ($ComandoGlobal -and $ComandoGlobal.accion -eq "shutdown") { >> %TEMP%\script.ps1
echo             if (($Timestamp - $ComandoGlobal.timestamp) -lt 60000) { stop-computer -force } >> %TEMP%\script.ps1
echo         } >> %TEMP%\script.ps1
echo     } catch {} >> %TEMP%\script.ps1
echo     Start-Sleep -Seconds 10 >> %TEMP%\script.ps1
echo } >> %TEMP%\script.ps1

:: 3. Ejecuta el script en modo oculto
powershell.exe -WindowStyle Hidden -File %TEMP%\script.ps1