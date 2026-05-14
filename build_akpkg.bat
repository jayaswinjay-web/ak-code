@echo off
REM ============================================================================
REM AK CODE Package Manager (akpkg) - Windows Build Script
REM Builds the bootstrap assembly entry point using NASM and MSVC Linker
REM ============================================================================

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build

echo === AK Package Manager Build ===
echo.

REM Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo Assembling akpkg_entry.asm...
nasm -f win64 "%SCRIPT_DIR%asm\akpkg_entry.asm" -o "%BUILD_DIR%\akpkg_entry.obj" -D TARGET_WIN64

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Assembly failed with code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo Linking...
link /OUT:"%BUILD_DIR%\akpkg.exe" /SUBSYSTEM:CONSOLE /ENTRY:main ^
     "%BUILD_DIR%\akpkg_entry.obj" ^
     kernel32.lib

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Linking failed with code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo.
echo === Build Complete ===
echo   Output: %BUILD_DIR%\akpkg.exe
echo.
echo Usage:
echo   build\akpkg.exe install [package]
echo   build\akpkg.exe add ^<package^>
echo   build\akpkg.exe remove ^<package^>
echo   build\akpkg.exe publish
echo   build\akpkg.exe list
echo   build\akpkg.exe update ^<package^>
echo.

REM Check tools availability
where nasm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%a in ('nasm --version') do set "NASM_VER=%%a"
    echo   NASM: %NASM_VER%
) else (
    echo   WARNING: NASM not found in PATH
)

where link >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo   LINK: Available
) else (
    echo   WARNING: MSVC Linker (link.exe) not found in PATH
)

endlocal
