@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "ROOT=%~dp0.."
if exist "%~dp0festivalim-local-env.cmd" call "%~dp0festivalim-local-env.cmd"

set "SDK=%ANDROID_SDK_ROOT%"
if not defined SDK if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "SDK=%LOCALAPPDATA%\Android\Sdk"
set "ADB=%SDK%\platform-tools\adb.exe"

set "GODOT=%GODOT_EXE%"
if not defined GODOT for %%G in (godot.exe Godot.exe Godot_v4.7.2-stable_win64.exe) do (
  if not defined GODOT for /f "delims=" %%P in ('where %%G 2^>nul') do if not defined GODOT set "GODOT=%%P"
)
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT=%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe" set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe" set "GODOT=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe"

if not exist "%ADB%" (
  echo ERROR: adb not found. Run PREPARE-ANDROID-DEV.cmd first.
  pause
  exit /b 1
)
if not defined GODOT (
  echo ERROR: Godot 4.7.2 executable not found.
  echo Set it once before running this file:
  echo set GODOT_EXE=C:\path\Godot_v4.7.2-stable_win64.exe
  pause
  exit /b 1
)
if not exist "%GODOT%" (
  echo ERROR: GODOT_EXE does not exist: %GODOT%
  pause
  exit /b 1
)

"%ADB%" start-server >nul 2>&1
"%ADB%" get-state >nul 2>&1
if errorlevel 1 (
  echo ERROR: Android phone is not connected/authorized.
  echo Enable Developer options and USB debugging on Xiaomi, reconnect USB and accept the RSA prompt.
  echo.
  "%ADB%" devices -l
  pause
  exit /b 1
)

if not exist "%ROOT%\build" mkdir "%ROOT%\build"
set "APK=%ROOT%\build\Festivalim-LOCAL-DEV.apk"
if exist "%APK%" del /q "%APK%"

echo.
echo [1/4] Validating Festivalim project...
"%GODOT%" --headless --path "%ROOT%" --editor --quit
if errorlevel 1 (
  echo ERROR: Godot project validation failed.
  pause
  exit /b 1
)

echo.
echo [2/4] Building Android APK locally...
"%GODOT%" --headless --path "%ROOT%" --export-debug "Android" "%APK%"
if errorlevel 1 (
  echo ERROR: Android export failed.
  echo Check Godot Editor Settings ^> Export ^> Android and install Android export templates for Godot 4.7.2.
  pause
  exit /b 1
)
if not exist "%APK%" (
  echo ERROR: APK was not created: %APK%
  pause
  exit /b 1
)

echo.
echo [3/4] Installing APK on connected phone...
"%ADB%" install -r "%APK%"
if errorlevel 1 (
  echo ERROR: adb install failed.
  echo If Android reports signature mismatch, verify the Festivalim development keystore in Godot.
  pause
  exit /b 1
)

echo.
echo [4/4] Starting Festivalim DEV...
"%ADB%" shell monkey -p ru.festivalim.match3.dev -c android.intent.category.LAUNCHER 1 >nul 2>&1

echo.
echo SUCCESS: local APK built, installed and launched.
echo APK: %APK%
echo.
echo For runtime errors run LOGCAT-FESTIVALIM.cmd
pause
