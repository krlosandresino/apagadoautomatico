@echo off
:: 1. Espera 30 segundos exactos antes de hacer cualquier cosa
timeout /t 30 /nobreak > null

:: 2. Copia este mismo archivo a la carpeta de inicio para que se ejecute solo al prender la PC
copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\" /y

:: 3. Crea el directorio persistente y seguro para el script
set "SCRIPT_DIR=C:\ProgramData\ControlPC"
mkdir "%SCRIPT_DIR%" 2>nul
set "SCRIPT_PATH=%SCRIPT_DIR%\script.ps1"

:: 4. Crea el script de fondo que habla con Firebase de forma invisible (con Usuario e IP)
echo $BaseURL = "https://apagadoautomatico-default-rtdb.firebaseio.com" > "%SCRIPT_PATH%"
echo $PC_ID = $env:COMPUTERNAME >> "%SCRIPT_PATH%"
echo while ($true) { >> "%SCRIPT_PATH%"
echo     $Timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds() >> "%SCRIPT_PATH%"
echo     $IP = (Get-NetIPAddress -AddressFamily IPv4 ^| Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } ^| Select-Object -First 1).IPAddress >> "%SCRIPT_PATH%"
echo     $StatusData = @{ ultimaConexion = $Timestamp; usuario = $env:USERNAME; ip = $IP } ^| ConvertTo-Json -Compress >> "%SCRIPT_PATH%"
echo     Invoke-RestMethod -Uri "$BaseURL/computadoras/$PC_ID.json?x-http-method-override=PATCH" -Method Post -Body $StatusData -ContentType "application/json" ^> $null >> "%SCRIPT_PATH%"
echo     try { >> "%SCRIPT_PATH%"
echo         $ComandoIndividual = Invoke-RestMethod -Uri "$BaseURL/computadoras/$PC_ID/comando.json" -Method Get >> "%SCRIPT_PATH%"
echo         if ($ComandoIndividual -eq "shutdown") { >> "%SCRIPT_PATH%"
echo             Invoke-RestMethod -Uri "$BaseURL/computadoras/$PC_ID/comando.json" -Method Delete ^> $null >> "%SCRIPT_PATH%"
echo             stop-computer -force >> "%SCRIPT_PATH%"
echo         } >> "%SCRIPT_PATH%"
echo     } catch {} >> "%SCRIPT_PATH%"
echo     try { >> "%SCRIPT_PATH%"
echo         $ComandoGlobal = Invoke-RestMethod -Uri "$BaseURL/comando_global.json" -Method Get >> "%SCRIPT_PATH%"
echo         if ($ComandoGlobal -and $ComandoGlobal.accion -eq "shutdown") { >> "%SCRIPT_PATH%"
echo             if (($Timestamp - $ComandoGlobal.timestamp) -lt 60000) { stop-computer -force } >> "%SCRIPT_PATH%"
echo         } >> "%SCRIPT_PATH%"
echo     } catch {} >> "%SCRIPT_PATH%"
echo     Start-Sleep -Seconds 10 >> "%SCRIPT_PATH%"
echo } >> "%SCRIPT_PATH%"

:: 5. Ejecuta el script en modo oculto desde la nueva ubicacion
powershell.exe -WindowStyle Hidden -File "%SCRIPT_PATH%"