@echo off
setlocal enabledelayedexpansion

:: Check Administrator permissions
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run this script as Administrator.
    pause
    exit /b 1
)

set "GO_VERSION_REQUIRED=1.18"
set "PROJECT_DIR=%CD%"
set "INSTALL_DIR=C:\Program Files\go-sock5-server"
set "SERVICE_NAME=go-sock5-server"
set "PORT=1438"

:: Check Go version
where go >nul 2>&1
if %errorLevel% neq 0 (
    echo Go is not installed. Please install Go %GO_VERSION_REQUIRED% or later.
    pause
    exit /b 1
)

for /f "tokens=3" %%i in ('go version') do set GO_VERSION=%%i
set GO_VERSION=%GO_VERSION:go=%
for /f "tokens=1,2 delims=." %%a in ("%GO_VERSION%") do (
    set GO_MAJOR=%%a
    set GO_MINOR=%%b
)
for /f "tokens=1,2 delims=." %%a in ("%GO_VERSION_REQUIRED%") do (
    set REQ_MAJOR=%%a
    set REQ_MINOR=%%b
)
if %GO_MAJOR% lss %REQ_MAJOR% (
    echo Go version %GO_VERSION_REQUIRED% or later is required. Current version: %GO_VERSION%
    pause
    exit /b 1
)
if %GO_MAJOR% equ %REQ_MAJOR% if %GO_MINOR% lss %REQ_MINOR% (
    echo Go version %GO_VERSION_REQUIRED% or later is required. Current version: %GO_VERSION%
    pause
    exit /b 1
)

:: Build project
echo Building project...
cd /d "%PROJECT_DIR%"
go build -o go-sock5-server.exe .\cmd\s5-server
if %errorLevel% neq 0 (
    echo Build failed. Please check your code.
    pause
    exit /b 1
)
echo Build successful.

:: Deploy
echo Deploying...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\bin" mkdir "%INSTALL_DIR%\bin"
if not exist "%INSTALL_DIR%\config" mkdir "%INSTALL_DIR%\config"
if not exist "%INSTALL_DIR%\logs" mkdir "%INSTALL_DIR%\logs"

:: Stop the service if it exists
sc query %SERVICE_NAME% >nul 2>&1
if %errorLevel% equ 0 (
    net stop %SERVICE_NAME%
    if %errorLevel% neq 0 (
        echo Failed to stop the service. It may be already stopped or access denied.
    )
)

:: Copy binary
copy /Y "%PROJECT_DIR%\go-sock5-server.exe" "%INSTALL_DIR%\bin\"
if %errorLevel% neq 0 (
    echo Failed to copy the binary. Please check permissions and try again.
    pause
    exit /b 1
)

:: Copy config if it exists, otherwise create a default config
if exist "%PROJECT_DIR%\config\config.tom" (
    copy /Y "%PROJECT_DIR%\config\config.tom" "%INSTALL_DIR%\config\"
    if %errorLevel% neq 0 (
        echo Failed to copy the config file. Please check permissions and try again.
        pause
        exit /b 1
    )
) else (
    echo Creating default config...
    (
        echo [proxy]
        echo user = "admin"
        echo ip = "0.0.0.0"
        echo password = "25251325"
        echo port = %PORT%
    ) > "%INSTALL_DIR%\config\config.tom"
)

:: Create or update the service
sc query %SERVICE_NAME% >nul 2>&1
if %errorLevel% equ 0 (
    sc config %SERVICE_NAME% binPath= "\"%INSTALL_DIR%\bin\go-sock5-server.exe\" -c \"%INSTALL_DIR%\config\config.tom\"" start= auto
) else (
    sc create %SERVICE_NAME% binPath= "\"%INSTALL_DIR%\bin\go-sock5-server.exe\" -c \"%INSTALL_DIR%\config\config.tom\"" start= auto DisplayName= "SOCKS5 Server"
    sc description %SERVICE_NAME% "SOCKS5 server implemented in Go"
)
if %errorLevel% neq 0 (
    echo Failed to create or update the service. Please check permissions and try again.
    pause
    exit /b 1
)

:: Start the service
echo Starting the service...
net start %SERVICE_NAME%
if %errorLevel% neq 0 (
    echo Failed to start the service. Please check the Windows Event Logs for more information.
    pause
    exit /b 1
)

:: Verify service status
sc query %SERVICE_NAME% | find "RUNNING"
if %errorLevel% neq 0 (
    echo Service is not running. Please check the Windows Event Logs for more information.
    pause
    exit /b 1
)

:: Open firewall port
netsh advfirewall firewall add rule name="%SERVICE_NAME%" dir=in action=allow protocol=TCP localport=%PORT%
if %errorLevel% neq 0 (
    echo Failed to add firewall rule. Please check permissions and try again.
    pause
    exit /b 1
)

echo Deployment completed successfully.
echo Service is running.
pause
