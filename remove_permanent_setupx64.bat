@echo off
echo ========================================================
echo   MSVC Portable Environment Cleanup Tool
echo ========================================================
echo.
echo WARNING: This will delete the user-level MSVC environment 
echo variables (INCLUDE, LIB, VCToolsVersion, etc.) and remove 
echo the portable paths from your User PATH variable.
echo.
pause

echo.
echo Scrubbing standard variables from the Registry...

:: Suppress errors (2>nul) just in case a variable doesn't exist
REG DELETE "HKCU\Environment" /F /V "VSCMD_ARG_HOST_ARCH" 2>nul
REG DELETE "HKCU\Environment" /F /V "VSCMD_ARG_TGT_ARCH" 2>nul
REG DELETE "HKCU\Environment" /F /V "VCToolsVersion" 2>nul
REG DELETE "HKCU\Environment" /F /V "WindowsSDKVersion" 2>nul
REG DELETE "HKCU\Environment" /F /V "VCToolsInstallDir" 2>nul
REG DELETE "HKCU\Environment" /F /V "WindowsSdkBinPath" 2>nul

:: Note: If you had pre-existing INCLUDE or LIB variables for other 
:: software, this will remove them. Usually, this is perfectly fine 
:: for a standard development machine.
REG DELETE "HKCU\Environment" /F /V "INCLUDE" 2>nul
REG DELETE "HKCU\Environment" /F /V "LIB" 2>nul

echo standard variables removed.
echo.
echo Cleaning up the User PATH...

:: Use PowerShell to split the PATH, filter out MSVC/SDK strings, and rebuild it
powershell -Command "$path = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($path) { $parts = $path -split ';'; $cleanParts = $parts | Where-Object { $_ -and $_ -notmatch 'VC\\Tools\\MSVC' -and $_ -notmatch 'Windows Kits\\10' }; $newPath = $cleanParts -join ';'; [Environment]::SetEnvironmentVariable('Path', $newPath, 'User'); Write-Host 'PATH cleaned successfully.' -ForegroundColor Green } else { Write-Host 'No User PATH found.' -ForegroundColor Yellow }"

echo.
echo ========================================================
echo UNINSTALL COMPLETE! 
echo ========================================================
echo IMPORTANT: Close all open terminals/command prompts so 
echo they can refresh and drop the deleted variables.
echo.
pause