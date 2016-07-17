:: Batch file run by conflux-toolbelt.exe (the only thing conflux-toolbelt.exe does)
:: Purpose: Fetches the conflux toolbelt and installs it at C:\Program Files\conflux
:: *Since "Program Files" access is required, conflux-toolbelt.exe must be run as an administrator.
:: C:\Program Files\conflux\bin must be added to PATH afterwards.

@echo off

set CONFLUX_CLI_URL="https://ds8ypexjwou5.cloudfront.net/toolbelt/conflux-cli.tgz"

:: Remove existing conflux directories/files just in case
cd /d C:\Program Files\
rmdir /s /q conflux
rmdir /s /q conflux-cli
del conflux-cli.tgz
del conflux-cli.tar

:: If wget is installed, prioritize that command.
where wget
if %ERRORLEVEL% == 0 goto useWGET

:: If wget isn't installed, check if curl is.
where curl
if %ERRORLEVEL% == 0 goto useCURL

:: If neither wget nor curl is installed, error out.
echo Error Installing Conflux Toolbelt: Either 'wget' or 'curl' is required to proceed with installation.
goto error

:: Fetch conflux-cli.tgz with wget
:useWGET
wget %CONFLUX_CLI_URL%
goto check7z

:: Fetch conflux-cli.tgz with curl
:useCURL
curl -O %CONFLUX_CLI_URL%
goto check7z

:: make sure 7-zip installed to extract the .tgz file. Error out if not installed.
:check7z
where 7z
if %ERRORLEVEL% == 0 goto extract
echo Error Installing Conflux Toolbelt: 7-zip is required to proceed with installation.
goto error

:: Extract the contents of conflux-cli.tgz into a conflux folder inside Program Files
:extract
7z x conflux-cli.tgz
7z x conflux-cli.tar
rename conflux-cli conflux
del conflux-cli.tgz
del conflux-cli.tar
xcopy /y "C:\Program Files\conflux\resources\windows\conflux.bat" "C:\Program Files\conflux\bin\conflux.bat*"

:commonExit
pause

:error
exit /b %ERRORLEVEL%
