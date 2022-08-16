# Go Sock5 Server
## Server
1. Change config: ```config/dev.tom```
2. Config structure
    ```yaml
    [proxy]
      user = "admin"
      ip = "127.0.0.1"
      password = "25251325"
      port = 1438
     ```
3. Run: go run cmd/s5-server/main.go -c config/dev.toml
## Client
1. Change config server
    ```go
   auth := proxy.Auth{
		User:     "admin",
		Password: "password",
	}
	dialer, err := proxy.SOCKS5("tcp", "ip:port", &auth, proxy.Direct)
   ```