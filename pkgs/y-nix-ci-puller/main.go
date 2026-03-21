package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

type Config struct {
	MQTTBroker   string
	MQTTPort     string
	MQTTUser     string
	MQTTPassword string
	MQTTClientID string
	AllowedSSIDs []string
	GCRootDir    string
	Topics       []string
}

func loadConfig() Config {
	hostname := getHostname()
	config := Config{
		MQTTBroker:   getEnv("MQTT_BROKER", "localhost"),
		MQTTPort:     getEnv("MQTT_PORT", "1883"),
		MQTTUser:     getEnv("MQTT_USER", ""),
		MQTTPassword: getEnv("MQTT_PASSWORD", ""),
		MQTTClientID: getEnv("MQTT_CLIENT_ID", fmt.Sprintf("ci-puller-%s", hostname)),
		GCRootDir:    getEnv("GCROOT_DIR", "/nix/var/nix/gcroots/ci-puller"),
		Topics:       os.Args[1:],
	}

	if ssids := getEnv("ALLOWED_SSIDS", ""); ssids != "" {
		config.AllowedSSIDs = strings.Split(ssids, ",")
	}

	if len(config.Topics) == 0 {
		log.Fatal("No topics specified. Pass MQTT topics as arguments.")
	}

	return config
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		return "unknown"
	}
	return hostname
}

// attrFromTopic extracts the last component of the topic as the attr name.
func attrFromTopic(topic string) string {
	parts := strings.Split(topic, "/")
	return parts[len(parts)-1]
}

// checkGCRoot returns true if the gcroot already points to the given path.
func checkGCRoot(gcrootDir, attr, storePath string) bool {
	link := filepath.Join(gcrootDir, attr)
	target, err := os.Readlink(link)
	if err != nil {
		return false
	}
	return target == storePath
}

// hasWiredCarrier checks if any wired (eth*/en*) interface has carrier.
func hasWiredCarrier() bool {
	entries, err := os.ReadDir("/sys/class/net")
	if err != nil {
		return false
	}
	for _, e := range entries {
		name := e.Name()
		if strings.HasPrefix(name, "eth") || strings.HasPrefix(name, "en") {
			carrier, err := os.ReadFile(filepath.Join("/sys/class/net", name, "carrier"))
			if err == nil && strings.TrimSpace(string(carrier)) == "1" {
				return true
			}
		}
	}
	return false
}

// currentSSID returns the SSID of the current wifi connection, or empty string.
// Uses "iw dev <iface> link" which works with any wifi backend (iwd, wpa_supplicant).
func currentSSID() string {
	entries, err := os.ReadDir("/sys/class/net")
	if err != nil {
		return ""
	}
	for _, e := range entries {
		name := e.Name()
		// Check if this is a wireless interface
		if _, err := os.Stat(filepath.Join("/sys/class/net", name, "wireless")); err != nil {
			continue
		}
		out, err := exec.Command("iw", "dev", name, "link").Output()
		if err != nil {
			continue
		}
		for _, line := range strings.Split(string(out), "\n") {
			line = strings.TrimSpace(line)
			if strings.HasPrefix(line, "SSID: ") {
				return strings.TrimPrefix(line, "SSID: ")
			}
		}
	}
	return ""
}

// checkNetwork returns true if we're on a suitable network for fetching.
func checkNetwork(allowedSSIDs []string) bool {
	if hasWiredCarrier() {
		return true
	}
	if len(allowedSSIDs) == 0 {
		// No SSID allowlist configured, allow any network
		return true
	}
	ssid := currentSSID()
	for _, allowed := range allowedSSIDs {
		if ssid == allowed {
			return true
		}
	}
	return false
}

// realiseStorePath runs nix-store --realise to fetch the path.
func realiseStorePath(storePath string) error {
	cmd := exec.Command("nix-store", "--realise", storePath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// createGCRoot creates/updates the gcroot symlink.
func createGCRoot(gcrootDir, attr, storePath string) error {
	if err := os.MkdirAll(gcrootDir, 0755); err != nil {
		return err
	}
	link := filepath.Join(gcrootDir, attr)
	// Atomic replace: create temp link, rename over
	tmp := link + ".tmp"
	os.Remove(tmp)
	if err := os.Symlink(storePath, tmp); err != nil {
		return err
	}
	return os.Rename(tmp, link)
}

type LoginSession struct {
	Session string  `json:"session"`
	UID     int     `json:"uid"`
	User    string  `json:"user"`
	Seat    *string `json:"seat"`
	Class   string  `json:"class"`
}

// sessionType returns the Type property of a session via loginctl show-session.
func sessionType(sessionID string) string {
	out, err := exec.Command("loginctl", "show-session", sessionID, "-p", "Type", "--value").Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

// notifyUsers sends a desktop notification to all graphical sessions.
func notifyUsers(attr, storePath string) {
	out, err := exec.Command("loginctl", "list-sessions", "--json=short").Output()
	if err != nil {
		log.Printf("Failed to list sessions: %v", err)
		return
	}

	var sessions []LoginSession
	if err := json.Unmarshal(out, &sessions); err != nil {
		log.Printf("Failed to parse sessions: %v", err)
		return
	}

	notified := make(map[int]bool)
	for _, s := range sessions {
		if notified[s.UID] {
			continue
		}
		if s.Class != "user" {
			continue
		}
		st := sessionType(s.Session)
		if st != "wayland" && st != "x11" {
			continue
		}

		// Get DBUS_SESSION_BUS_ADDRESS for this user
		dbusAddr := fmt.Sprintf("unix:path=/run/user/%d/bus", s.UID)

		cmd := exec.Command("runuser", "-u", s.User, "--",
			"notify-send",
			"--app-name=nix-ci-puller",
			fmt.Sprintf("CI build ready: %s", attr),
			storePath,
		)
		cmd.Env = append(os.Environ(),
			fmt.Sprintf("DBUS_SESSION_BUS_ADDRESS=%s", dbusAddr),
		)
		if err := cmd.Run(); err != nil {
			log.Printf("Failed to notify user %s: %v", s.User, err)
		} else {
			log.Printf("Notified user %s about %s", s.User, attr)
			notified[s.UID] = true
		}
	}
}

func handleMessage(config Config, attr string, storePath string) {
	storePath = strings.TrimSpace(storePath)
	if storePath == "" {
		return
	}

	if !strings.HasPrefix(storePath, "/nix/store/") {
		log.Printf("[%s] Ignoring invalid store path: %s", attr, storePath)
		return
	}

	log.Printf("[%s] Received store path: %s", attr, storePath)

	// Check if already fetched
	if checkGCRoot(config.GCRootDir, attr, storePath) {
		log.Printf("[%s] Already have this path, skipping", attr)
		return
	}

	// Check network
	if !checkNetwork(config.AllowedSSIDs) {
		log.Printf("[%s] No suitable network available, skipping", attr)
		return
	}

	// Fetch
	log.Printf("[%s] Fetching store path...", attr)
	if err := realiseStorePath(storePath); err != nil {
		log.Printf("[%s] Failed to realise: %v", attr, err)
		return
	}

	// Create GC root
	if err := createGCRoot(config.GCRootDir, attr, storePath); err != nil {
		log.Printf("[%s] Failed to create GC root: %v", attr, err)
		return
	}
	log.Printf("[%s] GC root created", attr)

	// Notify
	notifyUsers(attr, storePath)
}

func main() {
	log.Println("Starting nix-ci-puller")

	config := loadConfig()

	opts := mqtt.NewClientOptions()
	broker := fmt.Sprintf("tcp://%s:%s", config.MQTTBroker, config.MQTTPort)
	opts.AddBroker(broker)
	opts.SetClientID(config.MQTTClientID)
	if config.MQTTUser != "" {
		opts.SetUsername(config.MQTTUser)
		opts.SetPassword(config.MQTTPassword)
	}
	opts.SetAutoReconnect(true)
	opts.SetConnectRetry(false)
	opts.SetConnectTimeout(10 * time.Second)
	opts.SetCleanSession(true)
	opts.SetProtocolVersion(4) // MQTT 3.1.1

	opts.SetConnectionLostHandler(func(client mqtt.Client, err error) {
		log.Printf("MQTT connection lost: %v", err)
	})

	opts.SetOnConnectHandler(func(client mqtt.Client) {
		log.Println("MQTT connected, subscribing to topics...")
		for _, topic := range config.Topics {
			attr := attrFromTopic(topic)
			t := topic // capture
			a := attr
			token := client.Subscribe(t, 1, func(client mqtt.Client, msg mqtt.Message) {
				handleMessage(config, a, string(msg.Payload()))
			})
			token.Wait()
			if token.Error() != nil {
				log.Printf("Failed to subscribe to %s: %v", t, token.Error())
			} else {
				log.Printf("Subscribed to %s (attr: %s)", t, a)
			}
		}
	})

	log.Printf("Connecting to MQTT broker %s as %s...", broker, config.MQTTUser)
	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Failed to connect to MQTT: %v", token.Error())
	}

	// Wait for signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("Shutting down...")
	client.Disconnect(250)
}
