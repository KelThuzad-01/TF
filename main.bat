@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Simulador de Pesca
mode con cols=92 lines=40 >nul 2>&1

set "BASE=%~dp0"
set "ACUARIO=%BASE%acuario.csv"
set "HISTORIAL=%BASE%historial.csv"
set "ESTADO=%BASE%estado.dat"
set "LOG=%BASE%pesca.log"

call :inicializar
call :cargar_estado
call :log INFO "Simulador iniciado"
goto menu

:menu
call :cargar_estado
call :contar_acuario
cls
echo ========================================================================================
echo                              SIMULADOR DE PESCA
echo ========================================================================================
echo.
echo   Monedas: !MONEDAS!      Acuario: !OCUPACION!/!CAPACIDAD!      Racha: !RACHA!
echo.
echo                         1. Lanzar la caña
echo                         2. Mostrar acuario
echo                         3. Lista completa de peces
echo                         4. Ver estadísticas
echo                         5. Ampliar acuario
echo                         6. Vaciar acuario
echo                         7. Salir
echo.
choice /n /c 1234567 /m "Selecciona una opción: "
if errorlevel 7 goto salir
if errorlevel 6 goto vaciar_acuario
if errorlevel 5 goto ampliar_acuario
if errorlevel 4 goto estadisticas
if errorlevel 3 goto lista_peces
if errorlevel 2 goto mostrar_acuario
if errorlevel 1 goto lanzar
goto menu

:lanzar
cls
echo.
echo.                     ^|
echo.                     ^|
echo.                    [ ]
echo.          ~~~~~~~~~~~~~~~~~~~~~
call :log INFO "Caña lanzada"
set /a CICLOS=3 + !RANDOM! %% 5
set /a PASO=0

:espera
set /a PASO+=1
if !PASO! GTR !CICLOS! goto picada
choice /n /c RQX /t 2 /d X >nul 2>&1
if errorlevel 3 goto espera
if errorlevel 2 goto fallo_abandono
if errorlevel 1 goto pronto
goto espera

:picada
rem El tamaño y la rareza son independientes.
set /a TIRADA_TAMANO=!RANDOM! %% 100
if !TIRADA_TAMANO! LSS 45 (
  set /a ACIERTOS_NECESARIOS=1
  set /a DIFICULTAD=1
  set /a REACCION=3
  set /a BASE_TAMANO=20
) else if !TIRADA_TAMANO! LSS 80 (
  set /a ACIERTOS_NECESARIOS=2
  set /a DIFICULTAD=2
  set /a REACCION=2
  set /a BASE_TAMANO=70
) else (
  set /a ACIERTOS_NECESARIOS=3
  set /a DIFICULTAD=3
  set /a REACCION=1
  set /a BASE_TAMANO=130
)
set /a ACIERTOS=0
set /a PRIMER_ESTADO=1
call :log INFO "Picada dificultad=!DIFICULTAD! aciertos=!ACIERTOS_NECESARIOS! reacción=!REACCION!s"
echo.
goto elegir_estado

:elegir_estado
if !PRIMER_ESTADO! EQU 1 (
  set /a PRIMER_ESTADO=0
  goto oportunidad
)
set /a ESTADO_ALEATORIO=!RANDOM! %% 100
if !ESTADO_ALEATORIO! LSS 55 goto tiron
goto oportunidad

:oportunidad
set /a NIVEL_FIGURA=ACIERTOS_NECESARIOS - ACIERTOS + 2
call :figura_recoger !NIVEL_FIGURA!
choice /n /c RQX /t !REACCION! /d X >nul 2>&1
if errorlevel 3 goto escapa
if errorlevel 2 goto fallo_abandono
if errorlevel 1 goto acierto
goto escapa

:acierto
set /a ACIERTOS+=1
call :log INFO "Acierto !ACIERTOS! de !ACIERTOS_NECESARIOS!"
if !ACIERTOS! GEQ !ACIERTOS_NECESARIOS! goto capturar
goto elegir_estado

:tiron
set /a NIVEL_FIGURA=ACIERTOS_NECESARIOS - ACIERTOS + 2
set /a DURACION_TIRON=1 + !RANDOM! %% 3
set /a PASO_TIRON=0
call :log INFO "El pez tira durante !DURACION_TIRON! ciclos"

:tiron_paso
set /a PASO_TIRON+=1
call :figura_tiron !NIVEL_FIGURA!
choice /n /c RQX /t 1 /d X >nul 2>&1
if errorlevel 3 goto tiron_siguiente
if errorlevel 2 goto fallo_abandono
if errorlevel 1 goto roto

:tiron_siguiente
if !PASO_TIRON! LSS !DURACION_TIRON! goto tiron_paso
goto elegir_estado

:pronto
cls
echo ========================================================================================
echo                                  DEMASIADO PRONTO
echo ========================================================================================
echo.
echo.                                         [ ]
echo.
echo                             El pez todavía no había picado.
echo.
call :reiniciar_racha
call :log INFO "R pulsada antes de la picada"
pause
goto menu

:escapa
cls
echo ========================================================================================
echo                                 EL PEZ HA ESCAPADO
echo ========================================================================================
echo.
echo                             No has recogido a tiempo.
echo.
call :reiniciar_racha
call :log INFO "Pez escapado por tiempo"
pause
goto menu

:roto
cls
echo ========================================================================================
echo                                     HILO ROTO
echo ========================================================================================
call :figura_tiron 5
echo                         Has recogido mientras el pez tiraba.
echo.
call :reiniciar_racha
call :log INFO "Hilo roto durante un tirón"
pause
goto menu

:fallo_abandono
cls
echo ========================================================================================
echo                                CAPTURA ABANDONADA
echo ========================================================================================
echo.
echo                                  Has soltado el pez.
echo.
call :reiniciar_racha
call :log INFO "Captura abandonada"
pause
goto menu

:capturar
if !DIFICULTAD! EQU 1 set /a TAMANO=BASE_TAMANO + !RANDOM! %% 51
if !DIFICULTAD! EQU 2 set /a TAMANO=BASE_TAMANO + !RANDOM! %% 81
if !DIFICULTAD! EQU 3 set /a TAMANO=BASE_TAMANO + !RANDOM! %% 151
call :especie
set "BRILLANTE=No"
set /a TIRADA_BRILLANTE=!RANDOM! %% 200
if !TIRADA_BRILLANTE! EQU 0 set "BRILLANTE=Sí"
call :calcular_valor
call :actualizar_racha
call :comprobar_record

cls
echo ========================================================================================
echo                                  ¡PEZ CAPTURADO!
echo ========================================================================================
echo.
echo                         Especie : !PEZ!
echo                         Tamaño  : !TAMANO! cm
echo                         Nivel   : !NIVEL!
echo                         Rareza  : !RAREZA!
if /i "!BRILLANTE!"=="Sí" echo                         Variante : *** BRILLANTE ***
echo                         Valor   : !VALOR! monedas
echo                         Racha   : !RACHA!
if "!ES_RECORD!"=="1" echo                         NUEVO RÉCORD DE ESPECIE
echo.
echo                         [G] Guardar en el acuario
echo                         [V] Vender por !VALOR! monedas
echo.
choice /n /c GV /m "¿Qué quieres hacer? "
if errorlevel 2 goto vender_captura
if errorlevel 1 goto guardar_captura
goto guardar_captura

:guardar_captura
call :contar_acuario
if !OCUPACION! GEQ !CAPACIDAD! goto acuario_lleno
call :registrar_historial Guardado
>>"%ACUARIO%" echo "%date%","%time:~0,8%","!PEZ!",!TAMANO!,"!NIVEL!",!DIFICULTAD!,"!RAREZA!","!BRILLANTE!",!VALOR!
set "RC=!errorlevel!"
if not "!RC!"=="0" (
  call :log ERROR "No se pudo guardar en el acuario. Código=!RC! Archivo=!ACUARIO!"
  echo.
  echo ERROR al guardar en el acuario. Consulta pesca.log.
) else (
  call :log INFO "Guardado en acuario: !PEZ!, !TAMANO! cm, !RAREZA!, brillante=!BRILLANTE!"
  echo.
  echo Ejemplar guardado. Acuario: !OCUPACION!+1 / !CAPACIDAD!
)
echo.
pause
goto menu

:acuario_lleno
cls
echo ========================================================================================
echo                                  ACUARIO LLENO
echo ========================================================================================
echo.
echo                      Capacidad actual: !OCUPACION! / !CAPACIDAD!
echo.
call :datos_expansion
if "!PUEDE_AMPLIAR!"=="1" (
  echo             Próxima ampliación: !NUEVA_CAPACIDAD! espacios por !COSTE_EXPANSION! monedas.
  echo.
  echo                         [A] Ampliar ahora
  echo                         [V] Vender esta captura
  choice /n /c AV /m "Selecciona una opción: "
  if errorlevel 2 goto vender_captura
  if errorlevel 1 goto ampliar_desde_captura
) else (
  echo                    El acuario ya tiene la capacidad máxima.
  echo                    La captura debe venderse.
  echo.
  pause
  goto vender_captura
)
goto vender_captura

:ampliar_desde_captura
if !MONEDAS! LSS !COSTE_EXPANSION! (
  echo.
  echo No tienes monedas suficientes. Necesitas !COSTE_EXPANSION!.
  echo La captura se venderá.
  echo.
  pause
  goto vender_captura
)
set /a MONEDAS-=COSTE_EXPANSION
set /a CAPACIDAD=NUEVA_CAPACIDAD
set /a NIVEL_ACUARIO+=1
call :guardar_estado
call :log INFO "Acuario ampliado durante captura: capacidad=!CAPACIDAD!"
goto guardar_captura

:vender_captura
set /a MONEDAS+=VALOR
call :guardar_estado
call :registrar_historial Vendido
call :log INFO "Captura vendida: !PEZ!, valor=!VALOR!, saldo=!MONEDAS!"
echo.
echo Has vendido !PEZ! por !VALOR! monedas.
echo Saldo actual: !MONEDAS! monedas.
echo.
pause
goto menu

:registrar_historial
>>"%HISTORIAL%" echo "%date%","%time:~0,8%","!PEZ!",!TAMANO!,"!NIVEL!",!DIFICULTAD!,"!RAREZA!","!BRILLANTE!","%~1",!VALOR!
exit /b

:comprobar_record
set "ES_RECORD=1"
set /a RECORD_ANTERIOR=0
for /f "usebackq skip=1 tokens=3,4 delims=," %%A in ("%HISTORIAL%") do (
  if /i "%%~A"=="!PEZ!" if %%~B GTR !RECORD_ANTERIOR! set /a RECORD_ANTERIOR=%%~B
)
if !RECORD_ANTERIOR! GEQ !TAMANO! set "ES_RECORD=0"
exit /b

:calcular_valor
if /i "!RAREZA!"=="Común" set /a BASE_VALOR=5
if /i "!RAREZA!"=="Poco común" set /a BASE_VALOR=15
if /i "!RAREZA!"=="Raro" set /a BASE_VALOR=40
if /i "!RAREZA!"=="Épico" set /a BASE_VALOR=100
if /i "!RAREZA!"=="Legendario" set /a BASE_VALOR=300
set /a VALOR=BASE_VALOR + TAMANO / 4
if /i "!BRILLANTE!"=="Sí" set /a VALOR*=5
exit /b

:actualizar_racha
set /a RACHA+=1
if !RACHA! GTR !MEJOR_RACHA! set /a MEJOR_RACHA=RACHA
call :guardar_estado
exit /b

:reiniciar_racha
set /a RACHA=0
call :guardar_estado
exit /b

rem ) ... ( significa que se puede recoger.
:figura_recoger
set /a NIVEL=%~1
set /a ALTURA=2 + NIVEL / 3
if !ALTURA! GTR 5 set /a ALTURA=5
echo.
for /l %%I in (1,1,!ALTURA!) do (
  set /a SEP=2 + %%I * 3
  call :pareja ")" "(" !SEP!
)
for /l %%I in (!ALTURA!,-1,1) do (
  set /a SEP=2 + %%I * 3
  call :pareja ")" "(" !SEP!
)
echo.
exit /b

rem ( ... ) significa que el pez tira y hay que esperar.
:figura_tiron
set /a NIVEL=%~1
set /a ALTURA=2 + NIVEL / 3
if !ALTURA! GTR 5 set /a ALTURA=5
echo.
for /l %%I in (1,1,!ALTURA!) do (
  set /a SEP=2 + %%I * 3
  call :pareja "(" ")" !SEP!
)
for /l %%I in (!ALTURA!,-1,1) do (
  set /a SEP=2 + %%I * 3
  call :pareja "(" ")" !SEP!
)
echo.
exit /b

:pareja
set "IZQ=%~1"
set "DER=%~2"
set /a SEP=%~3
set /a MARGEN=40 - SEP / 2
set "A="
set "B="
for /l %%M in (1,1,!MARGEN!) do set "A=!A! "
for /l %%S in (1,1,!SEP!) do set "B=!B! "
echo(!A!!IZQ!!B!!DER!
exit /b

:especie
set /a TIRADA_RAREZA=!RANDOM! %% 100
if !TIRADA_RAREZA! LSS 55 (
  set /a INDICE=!RANDOM! %% 20
) else if !TIRADA_RAREZA! LSS 80 (
  set /a INDICE=20 + !RANDOM! %% 14
) else if !TIRADA_RAREZA! LSS 92 (
  set /a INDICE=34 + !RANDOM! %% 8
) else if !TIRADA_RAREZA! LSS 98 (
  set /a INDICE=42 + !RANDOM! %% 5
) else (
  set /a INDICE=47 + !RANDOM! %% 3
)
call :cargar_catalogo
set "PEZ=!PEZ[%INDICE%]!"
set "RAREZA=!RAR[%INDICE%]!"
if !DIFICULTAD! EQU 1 (set "NIVEL=Pequeño") else if !DIFICULTAD! EQU 2 (set "NIVEL=Mediano") else set "NIVEL=Grande"
exit /b

:cargar_catalogo
set "PEZ[0]=Trucha"
set "RAR[0]=Común"
set "PEZ[1]=Carpa"
set "RAR[1]=Común"
set "PEZ[2]=Perca"
set "RAR[2]=Común"
set "PEZ[3]=Sardina"
set "RAR[3]=Común"
set "PEZ[4]=Caballa"
set "RAR[4]=Común"
set "PEZ[5]=Boquerón"
set "RAR[5]=Común"
set "PEZ[6]=Jurel"
set "RAR[6]=Común"
set "PEZ[7]=Breca"
set "RAR[7]=Común"
set "PEZ[8]=Barbo"
set "RAR[8]=Común"
set "PEZ[9]=Gobio"
set "RAR[9]=Común"
set "PEZ[10]=Tilapia"
set "RAR[10]=Común"
set "PEZ[11]=Corvina"
set "RAR[11]=Común"
set "PEZ[12]=Boga"
set "RAR[12]=Común"
set "PEZ[13]=Mojarra"
set "RAR[13]=Común"
set "PEZ[14]=Rodaballo"
set "RAR[14]=Común"
set "PEZ[15]=Arenque"
set "RAR[15]=Común"
set "PEZ[16]=Besugo"
set "RAR[16]=Común"
set "PEZ[17]=Mújol"
set "RAR[17]=Común"
set "PEZ[18]=Pez gato"
set "RAR[18]=Común"
set "PEZ[19]=Lubina"
set "RAR[19]=Común"
set "PEZ[20]=Salmón"
set "RAR[20]=Poco común"
set "PEZ[21]=Lucio"
set "RAR[21]=Poco común"
set "PEZ[22]=Dorada"
set "RAR[22]=Poco común"
set "PEZ[23]=Bonito"
set "RAR[23]=Poco común"
set "PEZ[24]=Merluza"
set "RAR[24]=Poco común"
set "PEZ[25]=Lenguado"
set "RAR[25]=Poco común"
set "PEZ[26]=Rape"
set "RAR[26]=Poco común"
set "PEZ[27]=Dentón"
set "RAR[27]=Poco común"
set "PEZ[28]=Congrio"
set "RAR[28]=Poco común"
set "PEZ[29]=Esturión"
set "RAR[29]=Poco común"
set "PEZ[30]=Pez globo"
set "RAR[30]=Poco común"
set "PEZ[31]=Pez loro"
set "RAR[31]=Poco común"
set "PEZ[32]=Pez ángel"
set "RAR[32]=Poco común"
set "PEZ[33]=Barracuda"
set "RAR[33]=Poco común"
set "PEZ[34]=Siluro"
set "RAR[34]=Raro"
set "PEZ[35]=Atún"
set "RAR[35]=Raro"
set "PEZ[36]=Pez espada"
set "RAR[36]=Raro"
set "PEZ[37]=Marlín azul"
set "RAR[37]=Raro"
set "PEZ[38]=Mero gigante"
set "RAR[38]=Raro"
set "PEZ[39]=Pez luna"
set "RAR[39]=Raro"
set "PEZ[40]=Anguila eléctrica"
set "RAR[40]=Raro"
set "PEZ[41]=Mantarraya"
set "RAR[41]=Raro"
set "PEZ[42]=Atún rojo"
set "RAR[42]=Épico"
set "PEZ[43]=Tiburón martillo"
set "RAR[43]=Épico"
set "PEZ[44]=Tiburón blanco"
set "RAR[44]=Épico"
set "PEZ[45]=Celacanto"
set "RAR[45]=Épico"
set "PEZ[46]=Pez napoleón"
set "RAR[46]=Épico"
set "PEZ[47]=Pez remo"
set "RAR[47]=Legendario"
set "PEZ[48]=Tiburón ballena"
set "RAR[48]=Legendario"
set "PEZ[49]=Leviatán dorado"
set "RAR[49]=Legendario"
exit /b

:mostrar_acuario
call :contar_acuario
cls
echo ========================================================================================
echo                                      TU ACUARIO
echo ========================================================================================
echo.
set /a NUMERO=0
for /f "usebackq skip=1 tokens=1-9 delims=," %%A in ("%ACUARIO%") do (
  set /a NUMERO+=1
  set "MARCA="
  if /i "%%~H"=="Sí" set "MARCA=*** BRILLANTE ***"
  echo !NUMERO!. %%~C - %%~D cm - %%~G !MARCA! - Valor %%~I
)
if !NUMERO! EQU 0 echo El acuario está vacío.
echo.
echo Ocupación: !NUMERO! / !CAPACIDAD!
echo.
pause
goto menu

:lista_peces
cls
echo ========================================================================================
echo                              LISTA COMPLETA DE PECES
echo ========================================================================================
echo.
call :cargar_catalogo
set /a DESCUBIERTOS=0
set "RAREZA_ACTUAL="
for /l %%I in (0,1,49) do (
  if /i not "!RAR[%%I]!"=="!RAREZA_ACTUAL!" (
    set "RAREZA_ACTUAL=!RAR[%%I]!"
    echo.
    echo ------------------------------- !RAREZA_ACTUAL! -------------------------------
  )
  set /a RECORD_ESPECIE=0
  set "TIENE_BRILLANTE=??"
  for /f "usebackq skip=1 tokens=3,4,8 delims=," %%A in ("%HISTORIAL%") do (
    if /i "%%~A"=="!PEZ[%%I]!" (
      if %%~B GTR !RECORD_ESPECIE! set /a RECORD_ESPECIE=%%~B
      if /i "%%~C"=="Sí" set "TIENE_BRILLANTE=OK"
    )
  )
  if !RECORD_ESPECIE! EQU 0 (
    echo ??  !PEZ[%%I]!
  ) else (
    echo OK  !PEZ[%%I]! - Récord !RECORD_ESPECIE! cm - Brillante !TIENE_BRILLANTE!
    set /a DESCUBIERTOS+=1
  )
)
echo.
echo Descubiertos: !DESCUBIERTOS! / 50
echo.
pause
goto menu

:estadisticas
call :cargar_estado
cls
echo ========================================================================================
echo                                      ESTADÍSTICAS
echo ========================================================================================
echo.
set /a TOTAL=0,SUMA=0,MAYOR=0,BRILLANTES=0
set "PEZ_MAYOR=Ninguno"
for /f "usebackq skip=1 tokens=3,4,8 delims=," %%A in ("%HISTORIAL%") do (
  set /a TOTAL+=1,SUMA+=%%~B
  if %%~B GTR !MAYOR! set /a MAYOR=%%~B& set "PEZ_MAYOR=%%~A"
  if /i "%%~C"=="Sí" set /a BRILLANTES+=1
)
call :cargar_catalogo
set /a DESCUBIERTOS=0
for /l %%I in (0,1,49) do (
  findstr /i /l /c:",\"!PEZ[%%I]!\"," "%HISTORIAL%" >nul 2>&1
  if not errorlevel 1 set /a DESCUBIERTOS+=1
)
if !TOTAL! EQU 0 (
  echo Todavía no has capturado ningún pez.
) else (
  set /a MEDIA=SUMA/TOTAL
  echo Capturas totales : !TOTAL!
  echo Especies         : !DESCUBIERTOS! / 50
  echo Tamaño medio     : !MEDIA! cm
  echo Récord general   : !PEZ_MAYOR! de !MAYOR! cm
  echo Brillantes       : !BRILLANTES!
  echo Racha actual     : !RACHA!
  echo Mejor racha      : !MEJOR_RACHA!
  echo Monedas          : !MONEDAS!
)
echo.
pause
goto menu

:ampliar_acuario
call :cargar_estado
call :datos_expansion
cls
echo ========================================================================================
echo                                 AMPLIAR ACUARIO
echo ========================================================================================
echo.
echo                       Capacidad actual: !CAPACIDAD! espacios
echo                       Monedas actuales : !MONEDAS!
echo.
if "!PUEDE_AMPLIAR!"=="0" (
  echo                       El acuario ya está al máximo.
  echo.
  pause
  goto menu
)
echo                       Nueva capacidad : !NUEVA_CAPACIDAD! espacios
echo                       Precio           : !COSTE_EXPANSION! monedas
echo.
choice /n /c SN /m "¿Comprar la ampliación? [S/N]: "
if errorlevel 2 goto menu
if !MONEDAS! LSS !COSTE_EXPANSION! (
  echo.
  echo No tienes monedas suficientes.
  echo.
  pause
  goto menu
)
set /a MONEDAS-=COSTE_EXPANSION
set /a CAPACIDAD=NUEVA_CAPACIDAD
set /a NIVEL_ACUARIO+=1
call :guardar_estado
call :log INFO "Acuario ampliado: nivel=!NIVEL_ACUARIO!, capacidad=!CAPACIDAD!, saldo=!MONEDAS!"
echo.
echo Acuario ampliado a !CAPACIDAD! espacios.
echo.
pause
goto menu

:datos_expansion
set "PUEDE_AMPLIAR=1"
if !NIVEL_ACUARIO! EQU 0 set /a NUEVA_CAPACIDAD=20,COSTE_EXPANSION=100
if !NIVEL_ACUARIO! EQU 1 set /a NUEVA_CAPACIDAD=35,COSTE_EXPANSION=300
if !NIVEL_ACUARIO! EQU 2 set /a NUEVA_CAPACIDAD=55,COSTE_EXPANSION=750
if !NIVEL_ACUARIO! EQU 3 set /a NUEVA_CAPACIDAD=80,COSTE_EXPANSION=1500
if !NIVEL_ACUARIO! EQU 4 set /a NUEVA_CAPACIDAD=120,COSTE_EXPANSION=3000
if !NIVEL_ACUARIO! GEQ 5 set "PUEDE_AMPLIAR=0"
exit /b

:vaciar_acuario
cls
echo ========================================================================================
echo                                  VACIAR ACUARIO
echo ========================================================================================
echo.
echo Esta acción elimina los ejemplares guardados, pero conserva el catálogo, récords,
echo brillantes descubiertos, monedas y estadísticas históricas.
echo.
choice /n /c SN /m "¿Vaciar el acuario? [S/N]: "
if errorlevel 2 goto menu
>"%ACUARIO%" echo "Fecha","Hora","Especie","Tamano_cm","Nivel","Dificultad","Rareza","Brillante","Valor"
call :log INFO "Acuario vaciado"
goto menu

:contar_acuario
set /a OCUPACION=0
for /f "usebackq skip=1 delims=" %%A in ("%ACUARIO%") do set /a OCUPACION+=1
exit /b

:inicializar
if not exist "%ACUARIO%" >"%ACUARIO%" echo "Fecha","Hora","Especie","Tamano_cm","Nivel","Dificultad","Rareza","Brillante","Valor"
if not exist "%HISTORIAL%" >"%HISTORIAL%" echo "Fecha","Hora","Especie","Tamano_cm","Nivel","Dificultad","Rareza","Brillante","Destino","Valor"
if not exist "%ESTADO%" (
  >"%ESTADO%" echo MONEDAS=0
  >>"%ESTADO%" echo CAPACIDAD=10
  >>"%ESTADO%" echo NIVEL_ACUARIO=0
  >>"%ESTADO%" echo RACHA=0
  >>"%ESTADO%" echo MEJOR_RACHA=0
)
exit /b

:cargar_estado
set /a MONEDAS=0,CAPACIDAD=10,NIVEL_ACUARIO=0,RACHA=0,MEJOR_RACHA=0
for /f "usebackq tokens=1,2 delims==" %%A in ("%ESTADO%") do set /a %%A=%%B
exit /b

:guardar_estado
>"%ESTADO%" echo MONEDAS=!MONEDAS!
>>"%ESTADO%" echo CAPACIDAD=!CAPACIDAD!
>>"%ESTADO%" echo NIVEL_ACUARIO=!NIVEL_ACUARIO!
>>"%ESTADO%" echo RACHA=!RACHA!
>>"%ESTADO%" echo MEJOR_RACHA=!MEJOR_RACHA!
exit /b

:log
>>"%LOG%" echo [%date% %time:~0,8%] [%~1] %~2
exit /b

:salir
call :log INFO "Simulador cerrado"
endlocal
exit /b 0
