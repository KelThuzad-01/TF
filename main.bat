@echo off
title 🎣 Juego de Pesca - CMD (versión estable final)
setlocal enabledelayedexpansion

:inicio
cls
echo ===============================
echo       🎣 JUEGO DE PESCA
echo ===============================
echo.
echo Espera a que pique el pez...
echo No pulses R antes de tiempo o el hilo se romperá.
echo.
timeout /t 2 >nul

:: --- ESPERA LARGA (PICADA) ---
set /a wait_picar=%random% %% 16 + 5
set /a segundos_pasados=0

:espera_picar
set /a segundos_pasados+=1
choice /C RN /N /T 1 /D N >nul
set choice_error=%errorlevel%

if %choice_error%==1 (
    echo 💥 El pez ha roto el hilo por impaciencia.
    timeout /t 2 >nul
    goto inicio
)

if %segundos_pasados% GEQ %wait_picar% goto picado
goto espera_picar

:picado
cls
echo 🐟 ¡Ha picado! Pulsa R para recoger el hilo.
set /a tiempo_limite=%wait_picar%
set /a contador=0

:reaccion
set /a contador+=1
choice /C RN /N /T 1 /D N >nul
set choice_error=%errorlevel%

if %choice_error%==1 (
    echo ⬆️  ¡Buen reflejo!
    timeout /t 1 >nul
    goto combate
)

if %contador% GEQ %tiempo_limite% (
    echo 🐠 El pez se ha escapado...
    timeout /t 2 >nul
    goto inicio
)
goto reaccion

:combate
cls
echo ⚔️  El combate comienza...
timeout /t 2 >nul

set /a nivel=1
set /a maxniveles=5

:loop_niveles
if %nivel% GTR %maxniveles% goto capturado

set /a espera_tiron=%random% %% 9 + 2
cls
echo ===============================
echo Nivel %nivel% de %maxniveles%
echo ===============================
echo El pez está tirando...
set /a contador=0

:tiron
set /a contador+=1
choice /C RN /N /T 1 /D N >nul
set choice_error=%errorlevel%

if %choice_error%==1 (
    echo 💥 El pez ha roto el hilo por impaciencia.
    timeout /t 2 >nul
    goto inicio
)

if %contador% GEQ %espera_tiron% goto cansado
goto tiron

:cansado
echo.
echo El pez está cansado. Pulsa R para recoger el hilo.
set /a contador=0

:ventana
set /a contador+=1
choice /C RN /N /T 1 /D N >nul
set choice_error=%errorlevel%

if %choice_error%==1 (
    echo ⬆️  Recogiste el hilo correctamente.
    timeout /t 1 >nul
    set /a nivel+=1
    goto loop_niveles
)

if %contador% GEQ %espera_tiron% (
    echo 🐠 El pez se ha escapado...
    timeout /t 2 >nul
    goto inicio
)
goto ventana

:capturado
cls
set /a size=%random% %% 116 + 5
echo 🏆 ¡Has capturado un pez de %size% cm!
echo.
choice /C SN /N /M "¿Quieres seguir pescando? (S/N): " >nul
if errorlevel 2 exit /b 0
goto inicio
