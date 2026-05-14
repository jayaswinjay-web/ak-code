@echo off
REM ============================================================================
REM AK CODE Bootstrap Compiler - Windows Build Script
REM Builds the entire bootstrap compiler using NASM and MSVC Linker
REM ============================================================================

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build

echo === AK CODE Bootstrap Compiler Build ===
echo.

REM Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo Step 1: Assembling all source files...

echo   Assembling runtime.asm...
nasm -f win64 "%SCRIPT_DIR%asm\runtime.asm" -o "%BUILD_DIR%\runtime.obj" ^
     -D TARGET_WIN64

echo   Assembling entry_win.asm...
nasm -f win64 "%SCRIPT_DIR%asm\entry_win.asm" -o "%BUILD_DIR%\entry_win.obj" ^
     -D TARGET_WIN64

echo   Assembling lexer.asm...
nasm -f win64 "%SCRIPT_DIR%asm\lexer.asm" -o "%BUILD_DIR%\lexer.obj" ^
     -D TARGET_WIN64

echo   Assembling parser.asm...
nasm -f win64 "%SCRIPT_DIR%asm\parser.asm" -o "%BUILD_DIR%\parser.obj" ^
     -D TARGET_WIN64

echo   Assembling codegen.asm...
nasm -f win64 "%SCRIPT_DIR%asm\codegen.asm" -o "%BUILD_DIR%\codegen.obj" ^
     -D TARGET_WIN64

echo   Assembling linker_glue.asm...
nasm -f win64 "%SCRIPT_DIR%asm\linker_glue.asm" -o "%BUILD_DIR%\linker_glue.obj" ^
     -D TARGET_WIN64

echo.
echo Step 2: Linking...
link /OUT:"%BUILD_DIR%\akc.exe" /SUBSYSTEM:CONSOLE /ENTRY:WinMain ^
     "%BUILD_DIR%\entry_win.obj" ^
     "%BUILD_DIR%\lexer.obj" ^
     "%BUILD_DIR%\parser.obj" ^
     "%BUILD_DIR%\codegen.obj" ^
     "%BUILD_DIR%\runtime.obj" ^
     "%BUILD_DIR%\linker_glue.obj" ^
     kernel32.lib user32.lib

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Linking failed with code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo.
echo === Build Complete ===
echo   Output: %BUILD_DIR%\akc.exe
echo.
echo Usage:
echo   build\akc.exe source.ak [-o output]
echo.

REM Check if NASM is available
where nasm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%a in ('nasm --version') do set "NASM_VER=%%a"
    echo   NASM: %NASM_VER%
) else (
    echo   WARNING: NASM not found in PATH
)

endlocal
