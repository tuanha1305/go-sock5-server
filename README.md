# Go Sock5 Server

This project implements a SOCKS5 server in Go.

## Prerequisites

* Go 1.18 or later
* Root access on Linux or Administrator privileges on Windows

## Quick Start

1. Clone the repository:

```
git clone https://gitlab.9prints.com/tuanha/go-sock5-server.git
cd go-sock5-server
```

2. Run the build and deploy script:

- On Linux:
  ```
  sudo ./deploy.sh
  ```

- On Windows:
  ```
  Right-click on deploy.bat and select "Run as administrator"
  ```

## Build and Deploy Scripts

### Linux (`deploy.sh`)

The `deploy.sh` script automates the process of building the go-sock5-server, installing it, and setting up a systemd service. Here's what it does:

1. Checks for root privileges
2. Verifies the Go version
3. Builds the project
4. Installs the binary to `/opt/go-sock5-server/bin/`
5. Copies the configuration file (if present) to `/opt/go-sock5-server/config/`
6. Sets up a systemd service
7. Configures the firewall to allow the specified port

### Windows (`deploy.bat`)

The `deploy.bat` script performs similar actions for Windows:

1. Checks for Administrator privileges
2. Verifies the Go version
3. Builds the project
4. Installs the binary to `C:\Program Files\go-sock5-server\bin\`
5. Copies or creates the configuration file in `C:\Program Files\go-sock5-server\config\`
6. Sets up a Windows service
7. Configures the Windows Firewall to allow the specified port

## Configuration

The server uses a configuration file named `config.tom`. On both platforms, if the file doesn't exist, a default configuration will be created:

```
[proxy]
user = "admin"
ip = "0.0.0.0"
password = "25251325"
port = 1438
```

You can modify this file as needed before or after deployment.

## Service Management

### Linux (systemd)

After running the build_deploy script, the server will be set up as a systemd service named `go-sock5-server`. You can manage it using standard systemd commands:

* Start the service: `sudo systemctl start go-sock5-server`
* Stop the service: `sudo systemctl stop go-sock5-server`
* Restart the service: `sudo systemctl restart go-sock5-server`
* Check the status: `sudo systemctl status go-sock5-server`

### Windows

On Windows, the server is set up as a Windows service named "Go SOCKS5 Server". You can manage it using the Services application or command line:

Using Command Prompt:
* Start the service: `net start go-sock5-server`
* Stop the service: `net stop go-sock5-server`
* Check the status: `sc query go-sock5-server`

Using PowerShell:
* Start the service: `Start-Service go-sock5-server`
* Stop the service: `Stop-Service go-sock5-server`
* Restart the service: `Restart-Service go-sock5-server`
* Check the status: `Get-Service go-sock5-server`

## Logs

### Linux
Logs are stored in `/opt/go-sock5-server/logs/`:
* Standard output: `output.log`
* Standard error: `error.log`

### Windows
Logs are stored in `C:\Program Files\go-sock5-server\logs\`:
* Standard output: `output.log`
* Standard error: `error.log`

## Troubleshooting

If you encounter any issues:

1. Check the logs in the respective log directories
2. Ensure the configuration file is correct
3. Verify that the required ports are not in use by another application
4. On Windows, check the Windows Event Viewer for additional error information

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.