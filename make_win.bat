@echo off

set bios=mc1502bios


if exist %bios%.obj del %bios%.obj
if exist %bios%.lst del %bios%.lst
if exist %bios%.exe del %bios%.exe
if exist %bios%.bin del %bios%.bin

@echo *******************************************************************************
@echo Assembling BIOS
@echo *******************************************************************************
win32\wasm -zcm=tasm -d1 -e=1 -fe=nul -fo=%bios%.obj %bios%.asm
if errorlevel 1 goto errasm
if not exist %bios%.obj goto errasm

@echo.
@echo *******************************************************************************
@echo Generating Listing
@echo *******************************************************************************
win32\wdis -l=%bios%.lst -s=%bios%.asm %bios%.obj
if errorlevel 1 goto errlist
if not exist %bios%.lst goto errlist
echo Ok

@echo.
@echo *******************************************************************************
@echo Linking BIOS
@echo *******************************************************************************
win32\wlink format dos name %bios%.exe file %bios%.obj
del %bios%.obj
if not exist %bios%.exe goto errlink

@echo.
@echo *******************************************************************************
@echo Building ROM Images
@echo *******************************************************************************

win32\exe2rom /8 %bios%.exe %bios%.bin
del %bios%.exe

if exist test\picoxt.exe win32\inject /70D0 %bios%.bin test\picoxt.exe


@echo *******************************************************************************
@echo SUCCESS!: BIOS successfully built
@echo *******************************************************************************
goto end

:errasm
@echo.
@echo.
@echo *******************************************************************************
@echo ERROR: Error assembling BIOS
@echo *******************************************************************************
goto end

:errlist
@echo.
@echo.
@echo *******************************************************************************
@echo ERROR: Error generating listing file
@echo *******************************************************************************
goto end

:errlink
@echo.
@echo *******************************************************************************
@echo ERROR: Error linking BIOS
@echo *******************************************************************************
goto end

:end
if exist %bios%.obj del %bios%.obj
if exist %bios%.exe del %bios%.exe

set bios=

pause
