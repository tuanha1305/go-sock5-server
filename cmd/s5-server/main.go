package main

import (
	"flag"
	"fmt"
	"github.com/spf13/viper"
	"go-sock5-server/pkg/config"
	socks5 "go-sock5-server/pkg/sock5"
	"os"
)

var (
	conf           = config.Config{}
	file           string
	verbosityLevel int
)

func showHelp() {
	fmt.Printf("Usage:%s {params}\n", os.Args[0])
	fmt.Println("      -c {config file}")
	fmt.Println("      -h (show help info)")
}

func unmarshal(rawVal interface{}) bool {
	if err := viper.Unmarshal(rawVal); err != nil {
		fmt.Printf("config file %s loaded failed. %v\n", file, err)
		return false
	}
	return true
}

func load() bool {
	_, err := os.Stat(file)
	if err != nil {
		return false
	}

	viper.SetConfigFile(file)
	viper.SetConfigType("toml")

	err = viper.ReadInConfig()
	if err != nil {
		fmt.Printf("config file %s read failed. %v\n", file, err)
		return false
	}

	if !unmarshal(&conf) || !unmarshal(&config.Config{}) {
		return false
	}

	fmt.Printf("config %s load ok!\n", file)
	return true
}

func parse() bool {
	flag.StringVar(&file, "c", "conf/conf.toml", "config file")
	flag.IntVar(&verbosityLevel, "v", -1, "verbosity level, higher value - more logs")
	help := flag.Bool("h", false, "help info")
	flag.Parse()
	if !load() {
		return false
	}

	if *help {
		showHelp()
		return false
	}
	return true
}

func main() {
	if !parse() {
		showHelp()
		os.Exit(-1)
	}

	var serverConfig *socks5.Config
	if conf.ProxyConfig != nil && len(conf.ProxyConfig.User) > 0 && len(conf.ProxyConfig.Password) > 0 {
		cred := socks5.StaticCredentials{
			conf.ProxyConfig.User: conf.ProxyConfig.Password,
		}
		cator := socks5.UserPassAuthenticator{Credentials: cred}
		serverConfig = &socks5.Config{AuthMethods: []socks5.Authenticator{cator}}
	} else {
		// NO AUTH
		serverConfig = &socks5.Config{}
	}
	server, err := socks5.New(serverConfig)
	if err != nil {
		panic(err)
	}

	// Create SOCKS5 proxy on localhost port 8000
	if err := server.ListenAndServe("tcp", fmt.Sprintf("%s:%d", conf.ProxyConfig.Ip, conf.ProxyConfig.Port)); err != nil {
		panic(err)
	}
}
