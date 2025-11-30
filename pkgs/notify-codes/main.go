package main

import (
	"fmt"
	"log"
	"os/exec"
	"regexp"
	"strings"
	"time"

	"github.com/godbus/dbus/v5"
)

var authCodePatterns = []*regexp.Regexp{
	regexp.MustCompile(`\b(\d{3}-\d{3})\b`),
	regexp.MustCompile(`\b(\d{6})\b`),
	regexp.MustCompile(`\b(\d{5,8})\b`),
	regexp.MustCompile(`(?i)code[:\s]+([A-Z0-9]{4,8})`),
	regexp.MustCompile(`(?i)verification[:\s]+([A-Z0-9]{4,8})`),
}

func extractAuthCode(text string) string {
	var lastCode string
	for _, pattern := range authCodePatterns {
		matches := pattern.FindAllStringSubmatch(text, -1)
		if len(matches) > 0 && len(matches[len(matches)-1]) > 1 {
			lastCode = matches[len(matches)-1][1]
			break
		}
	}
	return lastCode
}

func monitorNotifications() error {
	conn, err := dbus.SessionBusPrivate()
	if err != nil {
		return fmt.Errorf("failed to connect to session bus: %w", err)
	}
	defer conn.Close()

	if err = conn.Auth(nil); err != nil {
		return fmt.Errorf("failed to authenticate: %w", err)
	}

	if err = conn.Hello(); err != nil {
		return fmt.Errorf("failed to send hello: %w", err)
	}

	rules := []string{
		"type='method_call',interface='org.freedesktop.Notifications',member='Notify'",
	}

	call := conn.BusObject().Call("org.freedesktop.DBus.Monitoring.BecomeMonitor", 0, rules, uint(0))
	if call.Err != nil {
		return fmt.Errorf("failed to become monitor: %w", call.Err)
	}

	log.Println("Listening for notifications...")

	msgChan := make(chan *dbus.Message, 10)
	conn.Eavesdrop(msgChan)

	var lastCode string
	var lastCodeTime time.Time

	for msg := range msgChan {
		log.Printf("DEBUG: Received message: Type=%v", msg.Type)

		if len(msg.Body) < 5 {
			log.Printf("DEBUG: Message body too short: %d elements", len(msg.Body))
			continue
		}

		appName, _ := msg.Body[0].(string)
		summary, _ := msg.Body[3].(string)
		body, _ := msg.Body[4].(string)

		//log.Printf("DEBUG: Notification from '%s': summary='%s' body='%s'", appName, summary, body)

		appNameLower := strings.ToLower(appName)
		if !strings.Contains(appNameLower, "kdeconnect") && !strings.Contains(appNameLower, "kde connect") {
			log.Printf("DEBUG: Skipping non-KDE Connect notification from '%s'", appName)
			continue
		}

		log.Printf("KDE Connect notification: %s - %s", summary, body)

		fullText := summary + " " + body
		if code := extractAuthCode(fullText); code != "" {
			log.Printf("Found authentication code: %s", code)

			// Strip dashes from codes like xxx-xxx
			codeToClip := strings.ReplaceAll(code, "-", "")

			if codeToClip == lastCode && time.Since(lastCodeTime) < 10*time.Second {
				log.Printf("DEBUG: Skipping duplicate code (copied %v ago)", time.Since(lastCodeTime))
				continue
			}

			cmd := exec.Command("wl-copy", codeToClip)
			if err := cmd.Run(); err != nil {
				log.Printf("Failed to copy to clipboard: %v", err)
			} else {
				log.Println("Code copied to clipboard!")
				exec.Command("notify-send", "Auth Code Copied", fmt.Sprintf("Copied: %s", codeToClip)).Run()
				lastCode = codeToClip
				lastCodeTime = time.Now()
			}
		}
	}

	return nil
}

func main() {
	if err := monitorNotifications(); err != nil {
		log.Fatalf("Error: %v", err)
	}
}
