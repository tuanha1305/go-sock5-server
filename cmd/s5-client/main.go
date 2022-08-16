package main

import (
	"crypto/tls"
	"errors"
	"fmt"
	"golang.org/x/net/proxy"
	"io"
	"log"
	"net/http"
	"time"
)

func main() {
	auth := proxy.Auth{
		User:     "admin",
		Password: "password",
	}
	dialer, err := proxy.SOCKS5("tcp", "ip:port", &auth, proxy.Direct)

	if err != nil {
		log.Fatalln("Error ", err)
	}
	transport := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		Dial:            dialer.Dial,
	}
	client := &http.Client{
		Transport: transport,
		Timeout:   60 * time.Second,
	}
	resp, err := client.Get("http://checkip.dyndns.org/")

	if err != nil {
		log.Fatalln("Error ", err)
	}

	if resp.StatusCode != http.StatusOK {
		log.Fatalln("Error ", errors.New(fmt.Sprint("Status code !200")))
	}
	bodyBytes, err := io.ReadAll(resp.Body)
	bodyString := string(bodyBytes)
	log.Print(bodyString)
}
