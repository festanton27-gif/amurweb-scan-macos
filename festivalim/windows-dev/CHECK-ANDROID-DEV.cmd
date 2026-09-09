@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "OUT=%~dp0festivalim-local-check.txt"
>"%OUT%" echo FESTIVALIM LOCAL ANDROID CHECK
>>"%OUT%" echo ==================================
>>"%OUT%" echo Date: %date% %time%
>>"%OUT%" echo Computer: %COMPUTERNAME%
>>"%OUT%" echo User: %USERNAME%
>>"%OUT%" echo.

call :line "Windows"
ver >>"%OUT%" 2>&1

call :line "Git"
where git >>"%OUT%" 2>&1
git --version >>"%OUT%" 2>&1

set "SDK="
if defined ANDROID_SDK_ROOT if exist "%ANDROID_SDK_ROOT%\platform-tools\adb.exe" set "SDK=%ANDROID_SDK_ROOT%"
if not defined SDK if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "SDK=%ANDROID_HOME%"
if not defined SDK if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "SDK=%LOCALAPPDATA%\Android\Sdk"

call :line "Android SDK"
if defined SDK (
  echo SDK=!SDK!>>"%OUT%"
  "!SDK!\platform-tools\adb.exe" version >>"%OUT%" 2>&1
) else (
  echo SDK NOT FOUND>>"%OUT%"
)

set "JDK="
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "JDK=%JAVA_HOME%"
if not defined JDK if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" set "JDK=%ProgramFiles%\Android\Android Studio\jbr"
if not defined JDK if exist "%ProgramFiles%\Android\Android Studio\jre\bin\java.exe" set "JDK=%ProgramFiles%\Android\Android Studio\jre"

call :line "Java / Android Studio JBR"
if defined JDK (
  echo JDK=!JDK!>>"%OUT%"
  "!JDK!\bin\java.exe" -version >>"%OUT%" 2>&1
) else (
  echo JDK NOT FOUND>>"%OUT%"
)

set "GODOT="
for %%G in (godot.exe Godot.exe Godot_v4.7.2-stable_win64.exe) do (
  if not defined GODOT for /f "delims=" %%P in ('where %%G 2^>nul') do if not defined GODOT set "GODOT=%%P"
)
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT=%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe" set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe" set "GODOT=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe"

call :line "Godot"
if defined GODOT (
  echo GODOT=!GODOT!>>"%OUT%"
  "!GODOT!" --version >>"%OUT%" 2>&1
) else (
  echo GODOT 4.7.2 NOT FOUND IN COMMON PATHS>>"%OUT%"
)

call :line "Connected Android devices"
if defined SDK (
  "!SDK!\platform-tools\adb.exe" devices -l >>"%OUT%" 2>&1
) else (
  echo Cannot check devices without adb.>>"%OUT%"
)

call :line "Expected project"
echo Script directory: %~dp0>>"%OUT%"
echo Project expected one level above windows-dev: %~dp0..>>"%OUT%"

call :line "RESULT"
if not defined SDK echo [FAIL] Android SDK / adb not found.>>"%OUT%"
if not defined JDK echo [FAIL] Java JDK/JBR not found.>>"%OUT%"
if not defined GODOT echo [WARN] Godot 4.7.2 not auto-detected.>>"%OUT%"
if defined SDK if defined JDK echo [OK] Android Studio toolchain detected.>>"%OUT%"

cls
type "%OUT%"
echo.
echo Saved: "%OUT%"
echo.
pause
exit /b

:line
>>"%OUT%" echo.
>>"%OUT%" echo ---- %~1 ----
exit /b
