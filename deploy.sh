#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GO_VERSION_REQUIRED="1.18"
PROJECT_DIR="$(pwd)"
INSTALL_DIR="/opt/go-sock5-server"
SERVICE_FILE="/etc/systemd/system/go-sock5-server.service"
PORT=1438

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_go_version() {
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed. Please install Go $GO_VERSION_REQUIRED or later."
        exit 1
    fi
    
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    if [ "$(printf '%s\n' "$GO_VERSION_REQUIRED" "$GO_VERSION" | sort -V | head -n1)" != "$GO_VERSION_REQUIRED" ]; then
        log_error "Go version $GO_VERSION_REQUIRED or later is required. Current version: $GO_VERSION"
        exit 1
    fi
    log_info "Go version check passed: $GO_VERSION"
}

# Build project
build_project() {
    log_info "Building project..."
    cd "$PROJECT_DIR" || exit
    
    # Clean previous build
    rm -f go-sock5-server
    
    if ! go build -o go-sock5-server ./cmd/s5-server; then
        log_error "Build failed. Please check your code."
        exit 1
    fi
    log_info "Build successful."
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    # Check for UFW (Uncomplicated Firewall)
    if command -v ufw >/dev/null 2>&1; then
        log_info "UFW detected. Opening port $PORT..."
        if ufw allow $PORT/tcp; then
            ufw --force reload
            log_info "UFW rule added successfully"
        else
            log_warn "Failed to add UFW rule"
        fi
    # Check for firewalld
    elif command -v firewall-cmd >/dev/null 2>&1; then
        log_info "firewalld detected. Opening port $PORT..."
        if firewall-cmd --zone=public --add-port=$PORT/tcp --permanent; then
            firewall-cmd --reload
            log_info "firewalld rule added successfully"
        else
            log_warn "Failed to add firewalld rule"
        fi
    # Check for iptables
    elif command -v iptables >/dev/null 2>&1; then
        log_info "iptables detected. Opening port $PORT..."
        if iptables -A INPUT -p tcp --dport $PORT -j ACCEPT; then
            # Save iptables rules (this may vary depending on the distribution)
            if [ -f /etc/redhat-release ]; then
                service iptables save
            elif [ -f /etc/debian_version ]; then
                mkdir -p /etc/iptables
                iptables-save > /etc/iptables/rules.v4
            else
                log_warn "Unable to save iptables rules automatically. Please save them manually."
            fi
            log_info "iptables rule added successfully"
        else
            log_warn "Failed to add iptables rule"
        fi
    else
        log_warn "No supported firewall detected. Please manually configure your firewall to open port $PORT."
    fi
}

# Check if service exists and is running
check_service_status() {
    if systemctl list-units --full -all | grep -Fq "go-sock5-server.service"; then
        log_info "Service exists, checking status..."
        if systemctl is-active --quiet go-sock5-server; then
            log_info "Service is currently running, stopping it..."
            systemctl stop go-sock5-server
            sleep 2
        fi
    else
        log_info "Service does not exist yet, will create new one"
    fi
}

# Deploy
deploy() {
    log_info "Starting deployment..."
    
    # Create an installation directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"/{bin,config,logs}
    
    # Check and stop service if needed
    check_service_status
    
    # Replace binary
    log_info "Installing binary..."
    cp "$PROJECT_DIR/go-sock5-server" "$INSTALL_DIR/bin/"
    chmod 755 "$INSTALL_DIR/bin/go-sock5-server"
    
    # Replace config if it exists
    if [ -f "$PROJECT_DIR/config/config.toml" ]; then
        log_info "Installing config file..."
        cp "$PROJECT_DIR/config/config.toml" "$INSTALL_DIR/config/"
        log_info "Config file: $INSTALL_DIR/config/config.toml"
    else
        log_warn "config.toml not found in $PROJECT_DIR/config/. Skipping config update."
    fi
    
    # Create systemd service file
    log_info "Creating systemd service..."
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Go SOCKS5 Server
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=$INSTALL_DIR/bin/go-sock5-server -c $INSTALL_DIR/config/config.toml
WorkingDirectory=$INSTALL_DIR
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3
StandardOutput=append:$INSTALL_DIR/logs/output.log
StandardError=append:$INSTALL_DIR/logs/error.log

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and restart service
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload
    
    log_info "Starting service..."
    if systemctl start go-sock5-server; then
        log_info "Service started successfully"
    else
        log_error "Failed to start service"
        systemctl status go-sock5-server
        exit 1
    fi
    
    log_info "Enabling service for auto-start..."
    systemctl enable go-sock5-server
    
    # Verify service status
    sleep 2
    if systemctl is-active --quiet go-sock5-server; then
        log_info "Service is running successfully"
        systemctl status go-sock5-server --no-pager -l
    else
        log_error "Service failed to start properly"
        systemctl status go-sock5-server --no-pager -l
        exit 1
    fi
    
    log_info "Deployment completed successfully."
}

# Main execution
log_info "Starting build and deploy process..."
check_root
check_go_version
build_project
deploy
configure_firewall
log_info "Process completed successfully!"

# Show final status
log_info "Final service status:"
systemctl status go-sock5-server --no-pager -l