@echo off
setlocal EnableDelayedExpansion

echo ========================================================
echo   Dynamic MSVC Permanent Environment Setup
echo ========================================================
echo.

:: 1. Get the MSVC Root Directory (Prompt or default to Current Directory)
set /p "USER_ROOT=Enter MSVC Root Directory (Press ENTER to use current directory): "
if "%USER_ROOT%"=="" (
    set "MSVC_ROOT=%CD%"
) else (
    set "MSVC_ROOT=%USER_ROOT%"
)

:: Safely strip a trailing slash if the user accidentally typed one
if "%MSVC_ROOT:~-1%"=="\" set "MSVC_ROOT=%MSVC_ROOT:~0,-1%"

echo.
echo Target MSVC Root: %MSVC_ROOT%

:: Basic sanity check to ensure we are in the right place
if not exist "%MSVC_ROOT%\VC\Tools\MSVC" (
    echo ERROR: Could not find VC\Tools\MSVC in %MSVC_ROOT%.
    echo Are you sure this is the correct directory?
    pause
    exit /b 1
)

:: 2. Auto-Detect the MSVC Version Folder
set "MSVC_VERSION="
for /f "delims=" %%F in ('dir /b /ad "%MSVC_ROOT%\VC\Tools\MSVC\" 2^>nul') do (
    set "MSVC_VERSION=%%F"
    goto :found_msvc
)
:found_msvc

if "%MSVC_VERSION%"=="" (
    echo ERROR: Could not detect an MSVC version inside %MSVC_ROOT%\VC\Tools\MSVC\
    pause
    exit /b 1
)
echo Detected MSVC Version: %MSVC_VERSION%

:: 3. Auto-Detect the Windows SDK Version Folder (Looking for 10.* format)
set "SDK_VERSION="
for /f "delims=" %%F in ('dir /b /ad "%MSVC_ROOT%\Windows Kits\10\bin\10.*" 2^>nul') do (
    set "SDK_VERSION=%%F"
    goto :found_sdk
)
:found_sdk

if "%SDK_VERSION%"=="" (
    echo ERROR: Could not detect a Windows SDK version inside %MSVC_ROOT%\Windows Kits\10\bin\
    pause
    exit /b 1
)
echo Detected Windows SDK Version: %SDK_VERSION%
echo.

:: 4. Set base variables permanently
echo Setting base variables...
setx VSCMD_ARG_HOST_ARCH "x64" >nul
setx VSCMD_ARG_TGT_ARCH "x64" >nul
setx VCToolsVersion "%MSVC_VERSION%" >nul
setx WindowsSDKVersion "%SDK_VERSION%\" >nul
setx VCToolsInstallDir "%MSVC_ROOT%\VC\Tools\MSVC\%MSVC_VERSION%\" >nul
setx WindowsSdkBinPath "%MSVC_ROOT%\Windows Kits\10\bin\" >nul

:: 5. Set INCLUDE and LIB paths dynamically
echo Setting INCLUDE paths...
setx INCLUDE "%MSVC_ROOT%\VC\Tools\MSVC\%MSVC_VERSION%\include;%MSVC_ROOT%\Windows Kits\10\Include\%SDK_VERSION%\ucrt;%MSVC_ROOT%\Windows Kits\10\Include\%SDK_VERSION%\shared;%MSVC_ROOT%\Windows Kits\10\Include\%SDK_VERSION%\um;%MSVC_ROOT%\Windows Kits\10\Include\%SDK_VERSION%\winrt;%MSVC_ROOT%\Windows Kits\10\Include\%SDK_VERSION%\cppwinrt" >nul

echo Setting LIB paths...
setx LIB "%MSVC_ROOT%\VC\Tools\MSVC\%MSVC_VERSION%\lib\x64;%MSVC_ROOT%\Windows Kits\10\Lib\%SDK_VERSION%\ucrt\x64;%MSVC_ROOT%\Windows Kits\10\Lib\%SDK_VERSION%\um\x64" >nul

:: 6. Update User PATH via PowerShell
echo Updating User PATH...
set "NEW_PATHS=%MSVC_ROOT%\VC\Tools\MSVC\%MSVC_VERSION%\bin\Hostx64\x64;%MSVC_ROOT%\Windows Kits\10\bin\%SDK_VERSION%\x64;%MSVC_ROOT%\Windows Kits\10\bin\%SDK_VERSION%\x64\ucrt"

:: Switched from -notmatch to -notlike to avoid PowerShell Regex escaping errors with dynamic backslashes
powershell -Command "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($userPath -notlike '*%MSVC_VERSION%\bin\Hostx64*') { [Environment]::SetEnvironmentVariable('Path', $userPath + ';' + '%NEW_PATHS%', 'User'); Write-Host 'PATH updated successfully.' -ForegroundColor Green } else { Write-Host 'MSVC paths already exist in your PATH.' -ForegroundColor Yellow }"

echo.
echo ========================================================
echo SUCCESS! Your environment is now fully configured.
echo ========================================================
echo IMPORTANT: Close all open terminals/command prompts so
echo they can refresh and load the new variables.
echo.
pause
