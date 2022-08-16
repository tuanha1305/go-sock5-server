package config

type Config struct {
	ProxyConfig *ProxyConfig `mapstructure:"proxy"`
}

type ProxyConfig struct {
	Ip       string `mapstructure:"ip"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	Port     int    `mapstructure:"port"`
}
