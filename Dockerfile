# Builder stage
FROM golang:alpine as builder

# Install git for fetching dependencies.
# You can remove 'git' if you don't have external dependencies or if you use Go Modules without external repos.
RUN apk add --no-cache git

WORKDIR /app

# Cache and install dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Compile the binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server ./cmd/s5-server/main.go

# Final stage
FROM alpine:latest  

# Add certificates for secure communications
RUN apk --no-cache add ca-certificates

# Copy the binary from the builder stage
COPY --from=builder /app/server .
COPY config/config.toml ./config/config.toml

# Non-root user for security
RUN adduser -D appuser
USER appuser

# Configuration and ports
ENTRYPOINT ["/server"]
CMD ["-c", "config/config.toml"]
EXPOSE 8080
