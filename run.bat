@echo off
setlocal
echo ===================================================
echo Starting DemandSense - Sales & Demand Analytics (R)
echo ===================================================

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

echo Using: %RSCRIPT_PATH%
"%RSCRIPT_PATH%" run.R
pause
