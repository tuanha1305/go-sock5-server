package config

type Config struct {
	ProxyConfig *ProxyConfig `mapstructure:"proxy"`
}

type ProxyConfig struct {
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	Port     int    `mapstructure:"port"`
}
