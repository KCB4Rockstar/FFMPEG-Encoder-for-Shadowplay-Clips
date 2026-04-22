@echo off
setlocal enabledelayedexpansion

rem === Base output folder on local PC ===
set "BASE_OUTPUT=C:\CFR"

rem === Count how many files were dropped ===
set count=0
for %%A in (%*) do (
    set /a count+=1
    set "file[!count!]=%%~A"
)

if !count! equ 0 (
    echo Drag and drop one or more video files onto this script.
    pause
    exit /b
)

echo Found !count! file(s) to process.
echo.

rem === Process each file sequentially with directory replication ===
for /L %%I in (1,1,!count!) do (
    set "input=!file[%%I]!"

    rem === Strip drive letter from input path and prepend BASE_OUTPUT
    set "relpath=!input:~2!"
    set "outpath=%BASE_OUTPUT%!relpath!"

    rem === Get output directory (everything except filename)
    for %%B in ("!outpath!") do set "outdir=%%~dpB"
    if not exist "!outdir!" mkdir "!outdir!" >nul 2>&1

    rem === Build output filename with _cfr and original extension
    for %%B in ("!outpath!") do set "outfile=!outdir!\%%~nB_cfr%%~xB"

    echo [%%I/!count!] Processing: !input!

    rem === Try copying all audio tracks first
    C:\ffmpeg\bin\ffmpeg.exe -y -i "!input!" -map 0 -c:v h264_nvenc -rc vbr -cq 14 -b:v 30M -maxrate 35M -bufsize 60M -g 60 -r 60 -c:a copy "!outfile!" 2>error.log

    rem === Check if FFmpeg failed (non-zero errorlevel)
    if errorlevel 1 (
        echo Copying audio failed, re-encoding all audio to AAC...
        C:\ffmpeg\bin\ffmpeg.exe -y -i "!input!" -map 0 -c:v h264_nvenc -rc vbr -cq 14 -b:v 30M -maxrate 35M -bufsize 60M -g 60 -r 60 -c:a aac -b:a 192k "!outfile!"
    )

    echo [%%I/!count!] Done: !outfile!
    echo.
)

echo All !count! file(s) processed.
pause
endlocal
