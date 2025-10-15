@echo off
title Juego de Pesca
chcp 65001 >nul
setlocal enabledelayedexpansion

set "savefile=peces.dat"
set "tempfile=peces_temp.txt"
set "tempsave=peces_new.dat"

:menu
cls
echo ============================
echo       JUEGO DE PESCA
echo ============================
echo 1. Comenzar partida
echo 2. Ver capturas
echo 3. Salir
echo ============================
set /p opcion="Elige una opción: "

if "%opcion%"=="1" goto pescar
if "%opcion%"=="2" goto mostrar
if "%opcion%"=="3" exit
goto menu

:pescar
cls
echo Lanzando la caña...
set /a espera=%random% %% 16 + 5
timeout /t %espera% >nul
echo ¡El pez ha picado!

set "input="
set /p input="¡Pulsa R para recoger!: "
if /i not "%input%"=="R" (
    echo El pez se escapó...
    pause
    goto menu
)

echo El combate comienza...
timeout /t 1 >nul

rem === 5 niveles de tensión ===
for /l %%i in (1,1,5) do (
    set /a tiempo_nivel=!random! %% 9 + 2
    echo El pez está tirando...
    timeout /t !tiempo_nivel! >nul
    echo El pez está cansado. ¡Pulsa R para recoger!
    set /p reco="> "
    if /i not "!reco!"=="R" (
        echo El pez se escapó...
        pause
        goto menu
    )
)

rem === Pesca exitosa ===
set /a tamano=%random% %% 120 + 10
set "peces=Atun Tiburon Salmon Trucha Pez_Espada Lubina Bacalao Dorada Sardina Pez_Gato Carpa Lenguado Robalo Mero Besugo Arenque Pargo Bonito Caballa Raya Pez_Luna"
set /a indice=%random% %% 20 + 1
for /f "tokens=%indice%" %%a in ("%peces%") do set "pez=%%a"

echo ¡Has capturado un %pez% de %tamano% cm!

rem === Guardar captura de forma acumulativa ===
if exist "%savefile%" (
    certutil -decode "%savefile%" "%tempfile%" >nul 2>&1
) else (
    >"%tempfile%" echo === REGISTRO DE CAPTURAS ===
)

echo %date% %time% - %pez% (%tamano% cm) >> "%tempfile%"

rem Crear nuevo archivo codificado aparte y reemplazarlo al final
certutil -encode "%tempfile%" "%tempsave%" >nul 2>&1
move /y "%tempsave%" "%savefile%" >nul 2>&1
del "%tempfile%" >nul 2>&1

echo Captura guardada con éxito.
pause
goto menu

:mostrar
cls
if not exist "%savefile%" (
    echo No hay capturas registradas.
    pause
    goto menu
)

certutil -decode "%savefile%" "%tempfile%" >nul 2>&1
type "%tempfile%"
del "%tempfile%" >nul 2>&1
pause
goto menu
