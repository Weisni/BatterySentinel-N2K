@echo off
setlocal
set "ORION_QR_PYTHON=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if not exist "%ORION_QR_PYTHON%" (
  echo Codex bundled Python was not found. Use Python with reportlab and pypdf.
  pause
  exit /b 1
)
"%ORION_QR_PYTHON%" "%~dp0create_service_wifi_manual.py" --force%*
if errorlevel 1 pause
