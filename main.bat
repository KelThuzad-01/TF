@echo off
setlocal EnableDelayedExpansion
title 🎣 Pesca Aventura
color 0A

:: Archivo donde se guardarán las capturas codificadas
set "logfile=pesca.dat"

:: Lista de peces (20 especies)
set "peces=Trucha_arcoíris Carpa_dorada Pez_gato Tiburón_azul Pez_espada Pez_globo Dorado Atún_rojo Salmón_rosado Bagre Lenguado Mero Pez_loro Robalo Pez_payaso Esturión Pez_ángel Bacalao Pez_león Perca"

:: Dibujos ASCII
set "ascii_Trucha_arcoíris=><(((°>"
set "ascii_Carpa_dorada=<º)))><"
set "ascii_Pez_gato=(=^･ω･^=)"
set "ascii_Tiburón_azul=^\/^   ^\/^"
set "ascii_Pez_espada=>-)))))o>"
set "ascii_Pez_globo=<°)))o<"
set "ascii_Dorado=><(((º>"
set "ascii_Atún_rojo=><((((*>"
set "ascii_Salmón_rosado=><(((º>"
set "ascii_Bagre=<º)))o>"
set "ascii_Lenguado=<·)))><"
set "ascii_Mero=<º)))#>"
set "ascii_Pez_loro=<°)))–>"
set "ascii_Robalo=><(((#>"
set "ascii_Pez_payaso=<º)))<>"
set "ascii_Esturión=><(((≡>"
set "ascii_Pez_ángel=><((*>"
set "ascii_Bacalao=><(((°>"
set "ascii_Pez_león=><(((π>"
set "ascii_Perca=><(((°º>"

:menu
cls
echo ============================================
echo        🎣 Bienvenido al Juego de Pesca
echo ============================================
echo.
echo  [1] Comenzar partida
echo  [2] Salir
echo  [3] Ver colección de peces
echo ============================================
echo.
set /p "opcion=Selecciona una opción: "
if "%opcion%"=="1" goto jugar
if "%opcion%"=="2" exit /b
if "%opcion%"=="3" goto ver_coleccion
goto menu

:jugar
cls
echo Esperando a que piquen...
echo (No pulses nada todavía)
echo.

:: Espera larga aleatoria (5–20 s)
set /a esperaLarga=%random% %% 16 + 5
for /l %%i in (1,1,%esperaLarga%) do (
    <nul set /p "=."
    timeout /t 1 >nul
)
echo.
echo ¡El pez ha picado! Pulsa R para recoger (tienes %esperaLarga% s).

:: ventana de reacción
set "enganchado=0"
for /l %%i in (1,1,%esperaLarga%) do (
    choice /C RN /N /T 1 /D N >nul
    if errorlevel 2 (
        rem nada
    ) else (
        set "enganchado=1"
        goto comienzo_pelea
    )
)
if "%enganchado%"=="0" (
    echo.
    echo ❌ No pulsaste R a tiempo. El pez se escapó.
    timeout /t 2 >nul
    goto menu
)

:comienzo_pelea
cls
echo 🎣 ¡Has enganchado! Comienza el combate (5 niveles)...
timeout /t 1 >nul

set /a nivel=1
set /a maxniveles=5

:nivel_loop
if %nivel% GTR %maxniveles% goto captura_exitosa

:: generar tiempo del nivel entre 2 y 10 s
set /a esperaNivel=%random% %% 9 + 2

cls
echo ===============================
echo Nivel %nivel% de %maxniveles%
echo ===============================
echo El pez está tirando...

:: etapa 1: mientras tira (si pulsas R aquí -> hilo roto)
set "rompio=0"
for /l %%t in (1,1,%esperaNivel%) do (
    <nul set /p "=."
    choice /C RN /N /T 1 /D N >nul
    if errorlevel 2 (
        rem nada
    ) else (
        set "rompio=1"
        goto hilo_roto
    )
)
if "%rompio%"=="1" goto hilo_roto

echo.
echo El pez está cansado. Pulsa R para recoger el hilo!

:: etapa 2: oportunidad de recoger
set "reaccionado=0"
for /l %%t in (1,1,%esperaNivel%) do (
    choice /C RN /N /T 1 /D N >nul
    if errorlevel 2 (
        rem sigue
    ) else (
        set "reaccionado=1"
        echo ⬆️  Has recogido el hilo de este nivel.
        timeout /t 1 >nul
        goto siguiente_nivel
    )
)
if "%reaccionado%"=="0" (
    echo ❌ No recogiste a tiempo. El pez se escapó.
    timeout /t 2 >nul
    goto menu
)

:hilo_roto
echo.
echo ❌ Pulsaste R durante el tirón. El hilo se ha roto.
timeout /t 2 >nul
goto menu

:siguiente_nivel
set /a nivel+=1
goto nivel_loop

:captura_exitosa
cls

:: elegir pez aleatorio correctamente
set /a index=%random% %% 20 + 1
set /a i=0
for %%a in (%peces%) do (
    set /a i+=1
    if !i! EQU %index% set "pez=%%a"
)
set /a tamano=%random% %% 80 + 20

echo 🏆 ¡Has capturado un %pez:_= % de %tamano% cm!
echo.
call :mostrar_ascii "%pez%"
echo.
:: Guardar captura usando certutil
set "tempfile=%temp%\pesca_temp.txt"
echo %pez:_= % - %tamano% cm> "%tempfile%"
if exist "%logfile%" (
    :: decodificar log existente
    certutil -decode "%logfile%" "%tempfile%.dec" >nul 2>nul
    type "%tempfile%.dec" >> "%tempfile%"
    del "%tempfile%.dec"
)
:: codificar todo nuevamente
certutil -encode "%tempfile%" "%logfile%" >nul
del "%tempfile%"
echo Guardado en la colección de manera segura.
echo.
echo --------------------------------------------
set /p "=Presiona ENTER para volver al menú..." <nul
pause >nul
goto menu

:mostrar_ascii
setlocal EnableDelayedExpansion
set "pez=%~1"
set "clave=%pez: =_%"
for /f "tokens=2 delims==" %%A in ('set ascii_ 2^>nul ^| findstr /i /c:"ascii_%clave%="') do (
    echo %%A
)
endlocal
exit /b

:ver_coleccion
cls
echo ============================================
echo           🎣 Colección de Peces
echo ============================================
echo.

if not exist "%logfile%" (
    echo Aún no has pescado ningún pez.
    echo.
    pause
    goto menu
)

:: decodificar temporalmente para mostrar
set "tempfile=%temp%\pesca_ver.txt"
certutil -decode "%logfile%" "%tempfile%" >nul 2>nul
type "%tempfile%"
del "%tempfile%"

echo.
echo --------------------------------------------
set /p "=Presiona ENTER para volver al menú..." <nul
pause >nul
goto menu
