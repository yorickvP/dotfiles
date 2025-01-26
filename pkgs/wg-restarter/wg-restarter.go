package main

import (
	"errors"
	"flag"
	"log"
	"os/exec"
	"time"
)

func main() {
	gateway := flag.String("gateway", "", "Gateway IP address to ping (required)")
	service := flag.String("service", "wireguard-wg-0", "Systemd service to restart")
	interval := flag.Int("interval", 120, "Check interval in seconds (default: 120)")
	flag.Parse()

	if *gateway == "" {
		log.Fatal("Gateway IP must be specified using -gateway flag")
	}

	checkInterval := time.Duration(*interval) * time.Second
	ticker := time.NewTicker(checkInterval)
	defer ticker.Stop()

	log.Printf("Starting monitor (check interval: %v, ping timeout: 2s)", checkInterval)
	good := false

	for range ticker.C {
		cmd := exec.Command("fping", "-c", "1", "-t", "2000", "-q", *gateway)
		err := cmd.Run()

		if err == nil {
			if !good {
				log.Printf("Gateway %s reachable", *gateway)
				good = true
			}
			continue
		}
		good = false

		var exitError *exec.ExitError
		if errors.As(err, &exitError) {
			switch exitError.ExitCode() {
			case 1:
				log.Printf("Gateway %s unreachable - restarting service", *gateway)
				restartService(*service)
			default:
				log.Fatalf("Critical fping error (code %d): %v", exitError.ExitCode(), err)
			}
		} else {
			log.Fatalf("Execution error: %v", err)
		}
	}
}

func restartService(service string) {
	cmd := exec.Command("systemctl", "restart", service)
	if err := cmd.Run(); err != nil {
		log.Printf("Service restart failed: %v", err)
	} else {
		log.Printf("Successfully restarted %s", service)
	}
}
