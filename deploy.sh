#!/bin/bash

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

GO_VERSION_REQUIRED="1.18"
PROJECT_DIR="$(pwd)"
INSTALL_DIR="/opt/go-sock5-server"
SERVICE_FILE="/etc/systemd/system/go-sock5-server.service"
PORT=1438

check_go_version() {
    if ! command -v go &> /dev/null; then
        echo "Go is not installed. Please install Go $GO_VERSION_REQUIRED or later."
        exit 1
    fi

    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    if [ "$(printf '%s\n' "$GO_VERSION_REQUIRED" "$GO_VERSION" | sort -V | head -n1)" != "$GO_VERSION_REQUIRED" ]; then
        echo "Go version $GO_VERSION_REQUIRED or later is required. Current version: $GO_VERSION"
        exit 1
    fi
}

# Build project
build_project() {
    cd "$PROJECT_DIR" || exit
    if ! go build -o go-sock5-server ./cmd/s5-server; then
        echo "Build failed. Please check your code."
        exit 1
    fi
    echo "Build successful."
}

# Configure firewall
configure_firewall() {
    echo "Configuring firewall..."

    # Check for UFW (Uncomplicated Firewall)
    if command -v ufw >/dev/null 2>&1; then
        echo "UFW detected. Opening port $PORT..."
        ufw allow $PORT/tcp
        ufw reload
    # Check for firewalld
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "firewalld detected. Opening port $PORT..."
        firewall-cmd --zone=public --add-port=$PORT/tcp --permanent
        firewall-cmd --reload
    # Check for iptables
    elif command -v iptables >/dev/null 2>&1; then
        echo "iptables detected. Opening port $PORT..."
        iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
        # Save iptables rules (this may vary depending on the distribution)
        if [ -f /etc/redhat-release ]; then
            service iptables save
        elif [ -f /etc/debian_version ]; then
            iptables-save > /etc/iptables/rules.v4
        else
            echo "Unable to save iptables rules automatically. Please save them manually."
        fi
    else
        echo "No supported firewall detected. Please manually configure your firewall to open port $PORT."
    fi
}

# Deploy
deploy() {
    # Create an installation directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"/{bin,config,logs}

    # Stop the service
    systemctl stop go-sock5-server || true

    # Replace binary
    cp "$PROJECT_DIR/go-sock5-server" "$INSTALL_DIR/bin/"
    chmod 755 "$INSTALL_DIR/bin/go-sock5-server"

    echo "$PROJECT_DIR/config/config.toml"

    # Replace config if it exists
    if [ -f "$PROJECT_DIR/config/config.toml" ]; then
        cp "$PROJECT_DIR/config/config.toml" "$INSTALL_DIR/config/"
    else
        echo "Warning: config.tom not found in the project directory. Skipping config update."
    fi

    # Replace systemd service file
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
    systemctl daemon-reload
    systemctl start go-sock5-server
    systemctl enable go-sock5-server

    echo "Deployment completed successfully."
}

# Main execution
echo "Starting build and deploy process..."
check_root
check_go_version
build_project
deploy
configure_firewall
echo "Process completed."
