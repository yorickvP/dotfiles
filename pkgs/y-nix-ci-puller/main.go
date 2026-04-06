package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"syscall"
	"text/tabwriter"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/fsnotify/fsnotify"
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

// HomeManagerStatus tracks one home-manager generation (per user).
type HomeManagerStatus struct {
	User           string `json:"user"`
	PulledPath     string `json:"pulled_path"`
	ActivePath     string `json:"active_path"`
	NeedsActivate  bool   `json:"needs_activate"`
}

// MachineStatus is published as retained JSON to yorick/ci-puller/status/{hostname}.
type MachineStatus struct {
	Hostname       string               `json:"hostname"`
	Timestamp      string               `json:"timestamp"`
	PulledPaths    map[string]string    `json:"pulled_paths"`
	RunningSystem  string               `json:"running_system"`
	BootedSystem   string               `json:"booted_system"`
	ProfileSystem  string               `json:"profile_system"`
	NeedsReboot    bool                 `json:"needs_reboot"`
	NeedsSwitch    bool                 `json:"needs_switch"`
	HomeManager    []HomeManagerStatus  `json:"home_manager"`
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
	}

	if ssids := getEnv("ALLOWED_SSIDS", ""); ssids != "" {
		config.AllowedSSIDs = strings.Split(ssids, ",")
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

// readSymlink reads a symlink target, returning empty string on error.
func readSymlink(path string) string {
	target, err := os.Readlink(path)
	if err != nil {
		return ""
	}
	return target
}

// isSystemPath returns true if the store path looks like a NixOS system config.
func isSystemPath(storePath string) bool {
	info, err := os.Stat(filepath.Join(storePath, "bin", "switch-to-configuration"))
	return err == nil && !info.IsDir()
}

// isHomeManagerPath returns true if the store path looks like a home-manager generation.
func isHomeManagerPath(storePath string) bool {
	info, err := os.Stat(filepath.Join(storePath, "activate"))
	return err == nil && !info.IsDir()
}

// resolveProfilePath follows a profile symlink chain to its final /nix/store target.
// NixOS profiles are typically: /nix/var/nix/profiles/system -> system-N-link -> /nix/store/...
// Home-manager profiles: ~/.local/state/nix/profiles/home-manager -> home-manager-N-link -> /nix/store/...
func resolveProfilePath(profileLink string) string {
	resolved, err := filepath.EvalSymlinks(profileLink)
	if err != nil {
		return ""
	}
	return resolved
}

// findHomeManagerStatuses scans /home/*/.local/state/nix/profiles/home-manager
// and /root/.local/state/nix/profiles/home-manager for active home-manager generations.
func findHomeManagerStatuses(pulledHM map[string]string) []HomeManagerStatus {
	var statuses []HomeManagerStatus

	// Candidate profile dirs: /home/*/... and /root/...
	var candidates []struct {
		user string
		path string
	}
	homeEntries, err := os.ReadDir("/home")
	if err == nil {
		for _, e := range homeEntries {
			if e.IsDir() {
				candidates = append(candidates, struct {
					user string
					path string
				}{e.Name(), filepath.Join("/home", e.Name(), ".local", "state", "nix", "profiles", "home-manager")})
			}
		}
	}
	candidates = append(candidates, struct {
		user string
		path string
	}{"root", "/root/.local/state/nix/profiles/home-manager"})

	for _, c := range candidates {
		activePath := resolveProfilePath(c.path)
		if activePath == "" {
			continue
		}

		// Find if any pulled path is a home-manager gen for this user.
		// The attr name convention from CI is typically user@host or just an identifier.
		// We match by checking all pulled HM paths.
		for attr, pulledPath := range pulledHM {
			st := HomeManagerStatus{
				User:       c.user,
				PulledPath: pulledPath,
				ActivePath: activePath,
			}
			// If the attr contains the username, prefer that match
			if strings.Contains(attr, c.user) || len(pulledHM) == 1 {
				st.NeedsActivate = pulledPath != activePath
				statuses = append(statuses, st)
				break
			}
			// Fallback: if there's only one user with an active profile, match it
			_ = attr
		}
	}

	return statuses
}

// collectStatus gathers the current machine status.
func collectStatus(gcrootDir string) MachineStatus {
	hostname := getHostname()

	pulled := make(map[string]string)
	pulledHM := make(map[string]string)
	entries, err := os.ReadDir(gcrootDir)
	if err == nil {
		for _, e := range entries {
			link := filepath.Join(gcrootDir, e.Name())
			target, err := os.Readlink(link)
			if err == nil {
				pulled[e.Name()] = target
				if isHomeManagerPath(target) {
					pulledHM[e.Name()] = target
				}
			}
		}
	}

	running := readSymlink("/run/current-system")
	booted := readSymlink("/run/booted-system")
	profile := resolveProfilePath("/nix/var/nix/profiles/system")

	needsReboot := booted != "" && profile != "" && booted != profile
	needsSwitch := running != "" && profile != "" && running != profile

	hmStatuses := findHomeManagerStatuses(pulledHM)

	return MachineStatus{
		Hostname:      hostname,
		Timestamp:     time.Now().UTC().Format(time.RFC3339),
		PulledPaths:   pulled,
		RunningSystem: running,
		BootedSystem:  booted,
		ProfileSystem: profile,
		NeedsReboot:   needsReboot,
		NeedsSwitch:   needsSwitch,
		HomeManager:   hmStatuses,
	}
}

// publishStatus publishes the current machine status as a retained MQTT message.
func publishStatus(client mqtt.Client, gcrootDir string) {
	status := collectStatus(gcrootDir)
	payload, err := json.Marshal(status)
	if err != nil {
		log.Printf("Failed to marshal status: %v", err)
		return
	}
	topic := fmt.Sprintf("yorick/ci-puller/status/%s", status.Hostname)
	token := client.Publish(topic, 1, true, payload)
	token.Wait()
	if token.Error() != nil {
		log.Printf("Failed to publish status: %v", token.Error())
	} else {
		log.Printf("Published status to %s", topic)
	}
}

func handleMessage(config Config, client mqtt.Client, attr string, storePath string) {
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

	// Publish updated status
	publishStatus(client, config.GCRootDir)

	// Notify
	notifyUsers(attr, storePath)
}

func runDaemon(config Config) {
	if len(config.Topics) == 0 {
		log.Fatal("No topics specified. Pass MQTT topics as arguments.")
	}

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
				handleMessage(config, client, a, string(msg.Payload()))
			})
			token.Wait()
			if token.Error() != nil {
				log.Printf("Failed to subscribe to %s: %v", t, token.Error())
			} else {
				log.Printf("Subscribed to %s (attr: %s)", t, a)
			}
		}

		// Publish initial status
		publishStatus(client, config.GCRootDir)
	})

	log.Printf("Connecting to MQTT broker %s as %s...", broker, config.MQTTUser)
	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Failed to connect to MQTT: %v", token.Error())
	}

	// Watch for symlink changes via inotify.
	// We watch specific directories and filter events by filename, since
	// watching /run directly would be extremely noisy.
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Printf("Failed to create inotify watcher: %v", err)
	} else {
		defer watcher.Close()

		// Names we care about when watching /run
		relevantRunNames := map[string]bool{
			"current-system": true,
			"booted-system":  true,
		}

		// Dirs where every event is relevant (gcroots, profiles)
		relevantDirs := map[string]bool{
			config.GCRootDir:         true,
			"/nix/var/nix/profiles":  true,
		}

		// Add home-manager profile dirs
		if homeEntries, err := os.ReadDir("/home"); err == nil {
			for _, e := range homeEntries {
				if e.IsDir() {
					hmDir := filepath.Join("/home", e.Name(), ".local", "state", "nix", "profiles")
					if _, err := os.Stat(hmDir); err == nil {
						relevantDirs[hmDir] = true
					}
				}
			}
		}
		if _, err := os.Stat("/root/.local/state/nix/profiles"); err == nil {
			relevantDirs["/root/.local/state/nix/profiles"] = true
		}

		// Watch /run with filename filtering
		if err := watcher.Add("/run"); err != nil {
			log.Printf("Failed to watch /run: %v", err)
		} else {
			log.Println("Watching /run for current-system/booted-system changes")
		}

		// Watch all relevant dirs
		for dir := range relevantDirs {
			if err := watcher.Add(dir); err != nil {
				log.Printf("Failed to watch %s: %v", dir, err)
			} else {
				log.Printf("Watching %s for changes", dir)
			}
		}

		// Event filter goroutine: only forward relevant events to debounceCh
		debounceCh := make(chan struct{}, 1)
		go func() {
			var debounceTimer *time.Timer
			for {
				select {
				case event, ok := <-watcher.Events:
					if !ok {
						return
					}
					if event.Op&(fsnotify.Create|fsnotify.Remove|fsnotify.Rename) == 0 {
						continue
					}
					dir := filepath.Dir(event.Name)
					base := filepath.Base(event.Name)

					relevant := false
					if dir == "/run" {
						relevant = relevantRunNames[base]
					} else {
						relevant = relevantDirs[dir]
					}
					if !relevant {
						continue
					}

					// Debounce: reset timer on each relevant event, fire after 2s of quiet
					if debounceTimer != nil {
						debounceTimer.Stop()
					}
					debounceTimer = time.AfterFunc(2*time.Second, func() {
						select {
						case debounceCh <- struct{}{}:
						default:
						}
					})
				case err, ok := <-watcher.Errors:
					if !ok {
						return
					}
					log.Printf("inotify error: %v", err)
				}
			}
		}()

		// Periodically republish status as fallback
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()

		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

		for {
			select {
			case <-ticker.C:
				publishStatus(client, config.GCRootDir)
			case <-debounceCh:
				log.Println("Detected symlink change, republishing status")
				publishStatus(client, config.GCRootDir)
			case <-sigChan:
				log.Println("Shutting down...")
				client.Disconnect(250)
				return
			}
		}
	}

	// Fallback if watcher creation failed: just use ticker + signals
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case <-ticker.C:
			publishStatus(client, config.GCRootDir)
		case <-sigChan:
			log.Println("Shutting down...")
			client.Disconnect(250)
			return
		}
	}
}

// shortenStorePath extracts the hash + name from a full store path for display.
func shortenStorePath(p string) string {
	p = strings.TrimPrefix(p, "/nix/store/")
	if len(p) > 40 {
		return p[:40] + "..."
	}
	return p
}

func runDashboard(config Config) {
	var mu sync.Mutex
	machines := make(map[string]*MachineStatus)

	opts := mqtt.NewClientOptions()
	broker := fmt.Sprintf("tcp://%s:%s", config.MQTTBroker, config.MQTTPort)
	opts.AddBroker(broker)
	opts.SetClientID(config.MQTTClientID + "-dashboard")
	if config.MQTTUser != "" {
		opts.SetUsername(config.MQTTUser)
		opts.SetPassword(config.MQTTPassword)
	}
	opts.SetAutoReconnect(true)
	opts.SetConnectTimeout(10 * time.Second)
	opts.SetCleanSession(true)
	opts.SetProtocolVersion(4)

	opts.SetOnConnectHandler(func(client mqtt.Client) {
		token := client.Subscribe("yorick/ci-puller/status/+", 1, func(client mqtt.Client, msg mqtt.Message) {
			var status MachineStatus
			if err := json.Unmarshal(msg.Payload(), &status); err != nil {
				log.Printf("Failed to parse status from %s: %v", msg.Topic(), err)
				return
			}
			mu.Lock()
			machines[status.Hostname] = &status
			mu.Unlock()
		})
		token.Wait()
		if token.Error() != nil {
			log.Fatalf("Failed to subscribe: %v", token.Error())
		}
	})

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Failed to connect to MQTT: %v", token.Error())
	}
	defer client.Disconnect(250)

	// Wait for retained messages to arrive
	fmt.Println("Collecting status from machines...")
	time.Sleep(2 * time.Second)

	// Also subscribe to the CI build topics to know what's expected
	// We read the retained messages from yorick/git/dotfiles/main/+
	expectedPaths := make(map[string]string)
	subToken := client.Subscribe("yorick/git/dotfiles/main/+", 1, func(client mqtt.Client, msg mqtt.Message) {
		host := attrFromTopic(msg.Topic())
		mu.Lock()
		expectedPaths[host] = strings.TrimSpace(string(msg.Payload()))
		mu.Unlock()
	})
	subToken.Wait()

	// Give time for retained CI messages
	time.Sleep(1 * time.Second)

	mu.Lock()
	defer mu.Unlock()

	if len(machines) == 0 {
		fmt.Println("No machines reported status.")
		return
	}

	// Sort hostnames
	var hosts []string
	for h := range machines {
		hosts = append(hosts, h)
	}
	sort.Strings(hosts)

	// NixOS system status
	fmt.Println("=== NixOS System ===")
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "HOST\tSTATUS\tPROFILE\tRUNNING\tBOOTED\tLAST SEEN")
	fmt.Fprintln(w, "----\t------\t-------\t-------\t------\t---------")

	for _, host := range hosts {
		m := machines[host]

		// Determine status
		status := "up-to-date"
		if m.NeedsReboot {
			status = "REBOOT NEEDED"
		} else if m.NeedsSwitch {
			status = "SWITCH NEEDED"
		}

		// Check if pulled path matches expected CI output
		if expected, ok := expectedPaths[host]; ok {
			if pulled, ok := m.PulledPaths[host]; ok {
				if pulled != expected {
					status = "PULL PENDING"
				}
			} else {
				status = "PULL PENDING"
			}
		}

		// Parse and format last seen
		lastSeen := m.Timestamp
		if t, err := time.Parse(time.RFC3339, m.Timestamp); err == nil {
			ago := time.Since(t).Truncate(time.Second)
			lastSeen = fmt.Sprintf("%s ago", ago)
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\n",
			host,
			status,
			shortenStorePath(m.ProfileSystem),
			shortenStorePath(m.RunningSystem),
			shortenStorePath(m.BootedSystem),
			lastSeen,
		)
	}
	w.Flush()

	// Home-manager status
	hasHM := false
	for _, host := range hosts {
		if len(machines[host].HomeManager) > 0 {
			hasHM = true
			break
		}
	}
	if hasHM {
		fmt.Println()
		fmt.Println("=== Home Manager ===")
		w = tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "HOST\tUSER\tSTATUS\tPULLED\tACTIVE")
		fmt.Fprintln(w, "----\t----\t------\t------\t------")
		for _, host := range hosts {
			for _, hm := range machines[host].HomeManager {
				hmStatus := "up-to-date"
				if hm.NeedsActivate {
					hmStatus = "ACTIVATE NEEDED"
				}
				fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n",
					host,
					hm.User,
					hmStatus,
					shortenStorePath(hm.PulledPath),
					shortenStorePath(hm.ActivePath),
				)
			}
		}
		w.Flush()
	}

	// Print details for machines needing action
	fmt.Println()
	for _, host := range hosts {
		m := machines[host]
		if m.NeedsReboot {
			fmt.Printf("  %s: profile differs from booted system (reboot to apply)\n", host)
		} else if m.NeedsSwitch {
			fmt.Printf("  %s: profile differs from running system (switch or reboot to apply)\n", host)
		}
		for _, hm := range m.HomeManager {
			if hm.NeedsActivate {
				fmt.Printf("  %s: home-manager for %s needs activation (run y-nix-ci-apply)\n", host, hm.User)
			}
		}
	}
}

func main() {
	config := loadConfig()

	if len(os.Args) > 1 && os.Args[1] == "dashboard" {
		runDashboard(config)
		return
	}

	log.Println("Starting nix-ci-puller")
	config.Topics = os.Args[1:]
	runDaemon(config)
}
