@echo off
setlocal enabledelayedexpansion
set "BASE=D:\language\ak code outer layer version 1\akcode"
set "NASM=C:\Program Files\NASM\nasm.exe"
set "LD=C:\Program Files\CodeBlocks\MinGW\bin\ld.exe"

echo === Assembling all files ===
pushd "%BASE%\asm"
for %%f in (runtime.asm entry_win.asm entry_linux.asm lexer.asm parser.asm codegen.asm linker_glue.asm) do (
    echo   %%~nf...
    "%NASM%" -f win64 -D TARGET_WIN64 "%%f" -o "%BASE%\build\%%~nf.obj"
    if !ERRORLEVEL! NEQ 0 (
        echo FAILED on %%f
        popd
        exit /b 1
    )
)
popd
echo === Assembly complete ===

echo.
echo === Linking ===
"%LD%" -o "%BASE%\build\akc.exe" ^
    "%BASE%\build\entry_win.obj" ^
    "%BASE%\build\lexer.obj" ^
    "%BASE%\build\parser.obj" ^
    "%BASE%\build\codegen.obj" ^
    "%BASE%\build\linker_glue.obj" ^
    "%BASE%\build\runtime.obj" ^
    -L"C:\Program Files\CodeBlocks\MinGW\x86_64-w64-mingw32\lib" -lkernel32 --subsystem console -e WinMain
if !ERRORLEVEL! EQU 0 (
    echo === Build successful: "%BASE%\build\akc.exe" ===
) else (
    echo Link failed
)
endlocal