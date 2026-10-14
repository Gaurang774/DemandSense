@echo off
setlocal enabledelayedexpansion

:: Ensure working directory is the DemandSense folder
cd /d "%~dp0"

echo ===================================================
echo Starting DemandSense - Sales ^& Demand Analytics (R)
echo ===================================================

:: Clean up any orphaned Rscript process left on port 8080 from a previously closed session
for /f "tokens=5" %%P in ('netstat -ano 2^>nul ^| findstr /r ":8080 " ^| findstr "LISTENING"') do (
    for /f "tokens=1" %%I in ('tasklist /fi "PID eq %%P" /nh 2^>nul ^| findstr /i "Rscript.exe"') do (
        echo Cleaning up previous background DemandSense server PID %%P...
        taskkill /f /pid %%P >nul 2>&1
    )
)

:: Locate Rscript executable
set "RSCRIPT_PATH=Rscript"
where Rscript >nul 2>nul
if %errorlevel% neq 0 (
    if exist "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" (
        set "RSCRIPT_PATH=C:\Program Files\R\R-4.6.1\bin\Rscript.exe"
    ) else (
        for /d %%D in ("C:\Program Files\R\R-*") do (
            if exist "%%D\bin\Rscript.exe" set "RSCRIPT_PATH=%%D\bin\Rscript.exe"
        )
    )
)

:: Validate Rscript was found
"%RSCRIPT_PATH%" --version >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] R / Rscript was not found on your system.
    echo Please ensure R is installed in C:\Program Files\R\ or added to your PATH.
    pause
    exit /b 1
)

echo Using: %RSCRIPT_PATH%
echo.

"%RSCRIPT_PATH%" run.R
if %errorlevel% neq 0 (
    echo.
    echo DemandSense stopped with an exit code of %errorlevel%.
    pause
)
