@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "ROOT=%~dp0.."
set "SDK="
if defined ANDROID_SDK_ROOT if exist "%ANDROID_SDK_ROOT%\platform-tools\adb.exe" set "SDK=%ANDROID_SDK_ROOT%"
if not defined SDK if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "SDK=%ANDROID_HOME%"
if not defined SDK if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "SDK=%LOCALAPPDATA%\Android\Sdk"

set "JDK="
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "JDK=%JAVA_HOME%"
if not defined JDK if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" set "JDK=%ProgramFiles%\Android\Android Studio\jbr"
if not defined JDK if exist "%ProgramFiles%\Android\Android Studio\jre\bin\java.exe" set "JDK=%ProgramFiles%\Android\Android Studio\jre"

if not defined SDK (
  echo ERROR: Android SDK not found.
  echo Expected default path: %LOCALAPPDATA%\Android\Sdk
  pause
  exit /b 1
)
if not defined JDK (
  echo ERROR: Android Studio JBR/JDK not found.
  pause
  exit /b 1
)

if not exist "%ROOT%\ci\dev-keystore.b64" (
  echo ERROR: Missing %ROOT%\ci\dev-keystore.b64
  pause
  exit /b 1
)

if not exist "%USERPROFILE%\.android" mkdir "%USERPROFILE%\.android"
set "KEYSTORE=%USERPROFILE%\.android\festivalim-dev.keystore"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$b64=(Get-Content -Raw '%ROOT%\ci\dev-keystore.b64') -replace '\s',''; [IO.File]::WriteAllBytes('%KEYSTORE%',[Convert]::FromBase64String($b64))"
if errorlevel 1 (
  echo ERROR: Could not restore development keystore.
  pause
  exit /b 1
)

"%JDK%\bin\keytool.exe" -list -keystore "%KEYSTORE%" -storepass festivalim-dev -alias festivalimdev >nul 2>&1
if errorlevel 1 (
  echo ERROR: Development keystore verification failed.
  pause
  exit /b 1
)

set "CFG=%~dp0festivalim-local-env.cmd"
>"%CFG%" echo @echo off
>>"%CFG%" echo set "ANDROID_SDK_ROOT=%SDK%"
>>"%CFG%" echo set "ANDROID_HOME=%SDK%"
>>"%CFG%" echo set "JAVA_HOME=%JDK%"
>>"%CFG%" echo set "FESTIVALIM_DEV_KEYSTORE=%KEYSTORE%"
>>"%CFG%" echo set "FESTIVALIM_DEV_KEY_ALIAS=festivalimdev"
>>"%CFG%" echo set "FESTIVALIM_DEV_KEY_PASS=festivalim-dev"

echo.
echo READY.
echo Android SDK: %SDK%
echo Java JDK:   %JDK%
echo Keystore:   %KEYSTORE%
echo.
echo Saved local environment:
echo %CFG%
echo.
echo In Godot 4.7.2 set once:
echo Android SDK Path = %SDK%
echo Java SDK Path    = %JDK%
echo Debug Keystore   = %KEYSTORE%
echo Keystore User    = festivalimdev
echo Keystore Pass    = festivalim-dev
echo.
echo Then BUILD-INSTALL-DEV.cmd will build and install directly on the phone.
pause
