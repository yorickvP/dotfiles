package main

import (
	"context"
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
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/lipgloss/table"
	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/fsnotify/fsnotify"
)

var (
	cellStyle    = lipgloss.NewStyle().Padding(0, 1)
	headerStyle  = cellStyle.Bold(true)
	matchStyle   = cellStyle.Foreground(lipgloss.Color("10"))
	sectionStyle = lipgloss.NewStyle().Bold(true).Underline(true)
	hintStyle    = lipgloss.NewStyle().Faint(true)
)

func styleForStatus(s string) lipgloss.Style {
	switch s {
	case "up-to-date":
		return cellStyle.Foreground(lipgloss.Color("10"))
	case "PULL NEEDED", "APPLY NEEDED":
		return cellStyle.Foreground(lipgloss.Color("11"))
	case "REBOOT NEEDED", "ACTIVATE NEEDED":
		return cellStyle.Foreground(lipgloss.Color("9"))
	}
	return cellStyle
}

type Config struct {
	MQTTBroker   string
	MQTTPort     string
	MQTTUser     string
	MQTTPassword string
	MQTTClientID string
	AllowedSSIDs []string
	GCRootDir    string
	NixCacheURL  string
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
		NixCacheURL:  getEnv("NIX_CACHE_URL", "https://cache.yori.cc/yorick"),
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

	hmStatuses := findHomeManagerStatuses(pulledHM)

	return MachineStatus{
		Hostname:      hostname,
		Timestamp:     time.Now().UTC().Format(time.RFC3339),
		PulledPaths:   pulled,
		RunningSystem: running,
		BootedSystem:  booted,
		ProfileSystem: profile,
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

// systemStatus reasons about machine state from the four observable values.
// Order matters: pull is upstream of apply, apply is upstream of reboot.
func systemStatus(profile, running, pulled, available string) string {
	if available != "" && pulled != available {
		return "PULL NEEDED"
	}
	if pulled != "" && pulled != profile {
		return "APPLY NEEDED"
	}
	if profile != "" && running != "" && profile != running {
		return "REBOOT NEEDED"
	}
	return "up-to-date"
}

// shortenStorePath returns a short hash prefix for visual diffing.
func shortenStorePath(p string) string {
	p = strings.TrimPrefix(p, "/nix/store/")
	if len(p) > 8 {
		return p[:8]
	}
	return p
}

// kernelInfo caches the kernel-related references of a system store path,
// fetched from the binary cache. nil while a fetch is in flight.
type kernelInfo struct {
	refs []string
	err  error
	done bool
}

// dashState is shared between the MQTT goroutines and the renderer.
type dashState struct {
	mu       sync.Mutex
	machines map[string]*MachineStatus
	expected map[string]string
	kernels  map[string]*kernelInfo
}

// snapshot returns shallow copies of the maps, so the renderer can run
// without holding the lock.
func (s *dashState) snapshot() (map[string]*MachineStatus, map[string]string, map[string]*kernelInfo) {
	s.mu.Lock()
	defer s.mu.Unlock()
	m := make(map[string]*MachineStatus, len(s.machines))
	for k, v := range s.machines {
		m[k] = v
	}
	e := make(map[string]string, len(s.expected))
	for k, v := range s.expected {
		e[k] = v
	}
	k := make(map[string]*kernelInfo, len(s.kernels))
	for kk, vv := range s.kernels {
		k[kk] = vv
	}
	return m, e, k
}

// kernelRefs filters a list of store-path references down to kernel-related
// ones (anything whose name starts with "linux-" — covers the kernel image and
// modules). Sorted for stable comparison.
func kernelRefs(refs []string) []string {
	var out []string
	for _, r := range refs {
		name := strings.TrimPrefix(r, "/nix/store/")
		if i := strings.IndexByte(name, '-'); i >= 0 && i+1 < len(name) {
			name = name[i+1:]
		}
		if strings.HasPrefix(name, "linux-") {
			out = append(out, r)
		}
	}
	sort.Strings(out)
	return out
}

// queryKernelRefs runs `nix path-info <path> --store <cacheURL> --json` and
// extracts kernel-related references.
func queryKernelRefs(ctx context.Context, path, cacheURL string) ([]string, error) {
	cmd := exec.CommandContext(ctx, "nix", "path-info", path, "--store", cacheURL, "--json")
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}
	// Recent nix emits an array; older or alternate formats may emit an object
	// keyed by store path. Try both.
	var arr []struct {
		References []string `json:"references"`
	}
	if err := json.Unmarshal(out, &arr); err == nil && len(arr) > 0 {
		return kernelRefs(arr[0].References), nil
	}
	var obj map[string]struct {
		References []string `json:"references"`
	}
	if err := json.Unmarshal(out, &obj); err == nil {
		for _, v := range obj {
			return kernelRefs(v.References), nil
		}
	}
	return nil, fmt.Errorf("unrecognized path-info output")
}

// ensureKernelRefs kicks off an async fetch for path if not already cached or
// in flight. notify is called when the fetch completes.
func (s *dashState) ensureKernelRefs(path, cacheURL string, notify func()) {
	if path == "" {
		return
	}
	s.mu.Lock()
	if _, ok := s.kernels[path]; ok {
		s.mu.Unlock()
		return
	}
	s.kernels[path] = &kernelInfo{} // mark in-flight (done=false)
	s.mu.Unlock()

	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		refs, err := queryKernelRefs(ctx, path, cacheURL)
		s.mu.Lock()
		s.kernels[path] = &kernelInfo{refs: refs, err: err, done: true}
		s.mu.Unlock()
		notify()
	}()
}

// waitForKernelRefs synchronously fetches kernel refs for the given paths in
// parallel. Used in oneshot mode.
func (s *dashState) waitForKernelRefs(paths []string, cacheURL string) {
	var wg sync.WaitGroup
	for _, p := range paths {
		if p == "" {
			continue
		}
		s.mu.Lock()
		if ki, ok := s.kernels[p]; ok && ki.done {
			s.mu.Unlock()
			continue
		}
		s.kernels[p] = &kernelInfo{}
		s.mu.Unlock()

		wg.Add(1)
		go func(p string) {
			defer wg.Done()
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			refs, err := queryKernelRefs(ctx, p, cacheURL)
			s.mu.Lock()
			s.kernels[p] = &kernelInfo{refs: refs, err: err, done: true}
			s.mu.Unlock()
		}(p)
	}
	wg.Wait()
}

// rebootHint returns "yes"/"no"/"?"/"" describing whether applying available
// onto running would require a kernel reboot.
func rebootHint(running, available string, kernels map[string]*kernelInfo) string {
	if available == "" || running == "" {
		return ""
	}
	if running == available {
		return "no"
	}
	rk, rok := kernels[running]
	ak, aok := kernels[available]
	if !rok || !aok || !rk.done || !ak.done || rk.err != nil || ak.err != nil {
		return "?"
	}
	if strings.Join(rk.refs, ",") == strings.Join(ak.refs, ",") {
		return "no"
	}
	return "yes"
}

func styleForReboot(s string) lipgloss.Style {
	switch s {
	case "no":
		return cellStyle.Foreground(lipgloss.Color("10"))
	case "yes":
		return cellStyle.Foreground(lipgloss.Color("9"))
	case "?":
		return cellStyle.Faint(true)
	}
	return cellStyle
}

func renderDashboard(machines map[string]*MachineStatus, expected map[string]string, kernels map[string]*kernelInfo) string {
	var hosts []string
	for h := range machines {
		hosts = append(hosts, h)
	}
	sort.Strings(hosts)
	if len(hosts) == 0 {
		return "No machines reported status."
	}

	// NixOS table — keep parallel sysRow slice carrying the full paths so
	// StyleFunc can compare without re-parsing the displayed (shortened) cells.
	type sysRow struct {
		status, reboot                                  string
		availFull, pulledFull, profileFull, runningFull string
	}
	sys := make([]sysRow, 0, len(hosts))
	sysRows := make([][]string, 0, len(hosts))
	for _, h := range hosts {
		m := machines[h]
		avail := expected[h]
		pulled := m.PulledPaths[h]
		status := systemStatus(m.ProfileSystem, m.RunningSystem, pulled, avail)
		reboot := rebootHint(m.RunningSystem, avail, kernels)
		lastSeen := m.Timestamp
		if t, err := time.Parse(time.RFC3339, m.Timestamp); err == nil {
			lastSeen = fmt.Sprintf("%s ago", time.Since(t).Truncate(time.Second))
		}
		sys = append(sys, sysRow{
			status:      status,
			reboot:      reboot,
			availFull:   avail,
			pulledFull:  pulled,
			profileFull: m.ProfileSystem,
			runningFull: m.RunningSystem,
		})
		sysRows = append(sysRows, []string{
			h, status,
			shortenStorePath(avail),
			shortenStorePath(pulled),
			shortenStorePath(m.ProfileSystem),
			shortenStorePath(m.RunningSystem),
			reboot,
			lastSeen,
		})
	}

	sysTable := table.New().
		Border(lipgloss.RoundedBorder()).
		Headers("HOST", "STATUS", "AVAILABLE", "PULLED", "PROFILE", "RUNNING", "REBOOT?", "LAST SEEN").
		Rows(sysRows...).
		StyleFunc(func(row, col int) lipgloss.Style {
			if row == table.HeaderRow {
				return headerStyle
			}
			r := sys[row]
			switch col {
			case 1:
				return styleForStatus(r.status)
			case 3, 4, 5:
				if r.availFull == "" {
					return cellStyle
				}
				var full string
				switch col {
				case 3:
					full = r.pulledFull
				case 4:
					full = r.profileFull
				case 5:
					full = r.runningFull
				}
				if full == r.availFull {
					return matchStyle
				}
			case 6:
				return styleForReboot(r.reboot)
			}
			return cellStyle
		})

	var b strings.Builder
	b.WriteString(sectionStyle.Render("NixOS System"))
	b.WriteString("\n")
	b.WriteString(sysTable.Render())

	// Home-manager table
	type hmRow struct {
		status  string
		matched bool
	}
	var hms []hmRow
	var hmRows [][]string
	for _, h := range hosts {
		for _, hm := range machines[h].HomeManager {
			st := "up-to-date"
			if hm.NeedsActivate {
				st = "ACTIVATE NEEDED"
			}
			hms = append(hms, hmRow{status: st, matched: !hm.NeedsActivate})
			hmRows = append(hmRows, []string{
				h, hm.User, st,
				shortenStorePath(hm.PulledPath),
				shortenStorePath(hm.ActivePath),
			})
		}
	}
	if len(hms) > 0 {
		hmTable := table.New().
			Border(lipgloss.RoundedBorder()).
			Headers("HOST", "USER", "STATUS", "PULLED", "ACTIVE").
			Rows(hmRows...).
			StyleFunc(func(row, col int) lipgloss.Style {
				if row == table.HeaderRow {
					return headerStyle
				}
				r := hms[row]
				switch col {
				case 2:
					return styleForStatus(r.status)
				case 3, 4:
					if r.matched {
						return matchStyle
					}
				}
				return cellStyle
			})
		b.WriteString("\n\n")
		b.WriteString(sectionStyle.Render("Home Manager"))
		b.WriteString("\n")
		b.WriteString(hmTable.Render())
	}

	// Action hints
	var actions []string
	for _, host := range hosts {
		m := machines[host]
		switch systemStatus(m.ProfileSystem, m.RunningSystem, m.PulledPaths[host], expected[host]) {
		case "PULL NEEDED":
			actions = append(actions, fmt.Sprintf("%s: CI build available but not yet pulled", host))
		case "APPLY NEEDED":
			actions = append(actions, fmt.Sprintf("%s: pulled build not yet activated (run y-nix-ci-apply)", host))
		case "REBOOT NEEDED":
			actions = append(actions, fmt.Sprintf("%s: profile differs from running system (reboot to apply)", host))
		}
		for _, hm := range m.HomeManager {
			if hm.NeedsActivate {
				actions = append(actions, fmt.Sprintf("%s: home-manager for %s needs activation (run y-nix-ci-apply)", host, hm.User))
			}
		}
	}
	if len(actions) > 0 {
		b.WriteString("\n")
		for _, a := range actions {
			b.WriteString("\n  ")
			b.WriteString(a)
		}
	}

	return b.String()
}

// connectMQTT wires up the dashboard subscriptions. notify is called after every
// state mutation; in watch mode it's program.Send, in oneshot it's a no-op.
// onPath is called with each store path observed (running/available) so the
// caller can opportunistically prefetch kernel refs.
func connectMQTT(config Config, state *dashState, notify func(), onPath func(string)) (mqtt.Client, error) {
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
		client.Subscribe("yorick/ci-puller/status/+", 1, func(_ mqtt.Client, msg mqtt.Message) {
			var status MachineStatus
			if err := json.Unmarshal(msg.Payload(), &status); err != nil {
				log.Printf("Failed to parse status from %s: %v", msg.Topic(), err)
				return
			}
			state.mu.Lock()
			state.machines[status.Hostname] = &status
			state.mu.Unlock()
			onPath(status.RunningSystem)
			notify()
		}).Wait()
		client.Subscribe("yorick/git/dotfiles/main/+", 1, func(_ mqtt.Client, msg mqtt.Message) {
			host := attrFromTopic(msg.Topic())
			path := strings.TrimSpace(string(msg.Payload()))
			state.mu.Lock()
			state.expected[host] = path
			state.mu.Unlock()
			onPath(path)
			notify()
		}).Wait()
	})

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		return nil, token.Error()
	}
	return client, nil
}

// watchModel is the bubbletea model for the live dashboard.
type watchModel struct {
	state *dashState
}

type tickMsg time.Time
type updateMsg struct{}

func tickCmd() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg { return tickMsg(t) })
}

func (m watchModel) Init() tea.Cmd { return tickCmd() }

func (m watchModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c", "esc":
			return m, tea.Quit
		}
	case tickMsg:
		return m, tickCmd()
	case updateMsg:
		// fall through to re-render
	}
	return m, nil
}

func (m watchModel) View() string {
	machines, expected, kernels := m.state.snapshot()
	body := renderDashboard(machines, expected, kernels)
	return body + "\n\n" + hintStyle.Render("press q to quit")
}

func runDashboard(config Config, watch bool) {
	state := &dashState{
		machines: make(map[string]*MachineStatus),
		expected: make(map[string]string),
		kernels:  make(map[string]*kernelInfo),
	}

	var program *tea.Program
	notify := func() {
		if program != nil {
			program.Send(updateMsg{})
		}
	}

	// In watch mode, opportunistically prefetch kernel refs as paths arrive.
	// In oneshot mode we skip live prefetch and run a synchronous batch after
	// the retained-message wait, to avoid racing the explicit fetch.
	onPath := func(string) {}
	if watch {
		onPath = func(p string) { state.ensureKernelRefs(p, config.NixCacheURL, notify) }
	}

	client, err := connectMQTT(config, state, notify, onPath)
	if err != nil {
		log.Fatalf("Failed to connect to MQTT: %v", err)
	}
	defer client.Disconnect(250)

	if watch {
		program = tea.NewProgram(watchModel{state: state}, tea.WithAltScreen())
		if _, err := program.Run(); err != nil {
			log.Fatalf("TUI error: %v", err)
		}
		return
	}

	// One-shot: brief wait for retained messages, then fetch kernel refs in
	// parallel, then render once.
	fmt.Println(hintStyle.Render("Collecting status from machines..."))
	time.Sleep(3 * time.Second)

	machines, expected, _ := state.snapshot()
	pathSet := map[string]bool{}
	for h, m := range machines {
		if m.RunningSystem != "" {
			pathSet[m.RunningSystem] = true
		}
		if a := expected[h]; a != "" {
			pathSet[a] = true
		}
	}
	if len(pathSet) > 0 {
		fmt.Println(hintStyle.Render("Looking up kernel references..."))
		paths := make([]string, 0, len(pathSet))
		for p := range pathSet {
			paths = append(paths, p)
		}
		state.waitForKernelRefs(paths, config.NixCacheURL)
	}

	machines, expected, kernels := state.snapshot()
	fmt.Println(renderDashboard(machines, expected, kernels))
}

func main() {
	config := loadConfig()

	if len(os.Args) > 1 && os.Args[1] == "dashboard" {
		watch := false
		for _, a := range os.Args[2:] {
			if a == "--watch" || a == "-w" {
				watch = true
			}
		}
		runDashboard(config, watch)
		return
	}

	log.Println("Starting nix-ci-puller")
	config.Topics = os.Args[1:]
	runDaemon(config)
}
