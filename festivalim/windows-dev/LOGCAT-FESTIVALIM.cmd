@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

if exist "%~dp0festivalim-local-env.cmd" call "%~dp0festivalim-local-env.cmd"
set "SDK=%ANDROID_SDK_ROOT%"
if not defined SDK if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "SDK=%LOCALAPPDATA%\Android\Sdk"
set "ADB=%SDK%\platform-tools\adb.exe"
set "OUT=%~dp0festivalim-logcat.txt"

if not exist "%ADB%" (
  echo ERROR: adb not found.
  pause
  exit /b 1
)

"%ADB%" get-state >nul 2>&1
if errorlevel 1 (
  echo ERROR: phone not connected/authorized.
  "%ADB%" devices -l
  pause
  exit /b 1
)

"%ADB%" logcat -c
"%ADB%" shell monkey -p ru.festivalim.match3.dev -c android.intent.category.LAUNCHER 1 >nul 2>&1
ping 127.0.0.1 -n 3 >nul

set "PID="
for /f "tokens=*" %%P in ('"%ADB%" shell pidof ru.festivalim.match3.dev 2^>nul') do set "PID=%%P"

if not defined PID (
  echo ERROR: Festivalim process is not running.
  echo Capturing last Android log anyway...
  "%ADB%" logcat -d -t 600 >"%OUT%" 2>&1
  type "%OUT%"
  echo.
  echo Saved: %OUT%
  pause
  exit /b 1
)

echo Festivalim PID: %PID%
echo Live log started. Reproduce the problem on the phone.
echo Press Ctrl+C when enough data is collected.
echo Log copy: %OUT%
echo.

"%ADB%" logcat --pid=%PID% | powershell -NoProfile -Command "$input | Tee-Object -FilePath '%OUT%'"
