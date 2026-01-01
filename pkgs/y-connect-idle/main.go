package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/godbus/dbus/v5"
)

type Config struct {
	MQTTBroker   string
	MQTTPort     string
	MQTTUser     string
	MQTTPassword string
	MQTTClientID string
	DeviceName   string
	EntityID     string
}

type HADiscoveryConfig struct {
	Name              string `json:"name"`
	StateTopic        string `json:"state_topic"`
	UniqueID          string `json:"unique_id"`
	DeviceClass       string `json:"device_class,omitempty"`
	PayloadOn         string `json:"payload_on"`
	PayloadOff        string `json:"payload_off"`
	Device            Device `json:"device"`
	AvailabilityTopic string `json:"availability_topic"`
}

type Device struct {
	Identifiers  []string `json:"identifiers"`
	Name         string   `json:"name"`
	Manufacturer string   `json:"manufacturer"`
	Model        string   `json:"model"`
}

func loadConfig() Config {
	config := Config{
		MQTTBroker:   getEnv("MQTT_BROKER", "localhost"),
		MQTTPort:     getEnv("MQTT_PORT", "1883"),
		MQTTUser:     getEnv("MQTT_USER", ""),
		MQTTPassword: getEnv("MQTT_PASSWORD", ""),
		MQTTClientID: getEnv("MQTT_CLIENT_ID", fmt.Sprintf("connect-idle-%s", getHostname())),
		DeviceName:   getEnv("DEVICE_NAME", getHostname()),
		EntityID:     getEnv("ENTITY_ID", "active"),
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

func connectMQTT(config Config) (mqtt.Client, error) {
	opts := mqtt.NewClientOptions()
	broker := fmt.Sprintf("tcp://%s:%s", config.MQTTBroker, config.MQTTPort)
	opts.AddBroker(broker)
	opts.SetClientID(config.MQTTClientID)
	if config.MQTTUser != "" {
		opts.SetUsername(config.MQTTUser)
		opts.SetPassword(config.MQTTPassword)
	}
	opts.SetWill(getAvailabilityTopic(config), "offline", 1, true)
	opts.SetAutoReconnect(true)
	opts.SetConnectRetry(true)

	// Set up connection state handlers
	opts.SetConnectionLostHandler(func(client mqtt.Client, err error) {
		log.Printf("MQTT connection lost: %v", err)
	})

	opts.SetOnConnectHandler(func(client mqtt.Client) {
		log.Println("MQTT connected/reconnected")
		publishAvailability(client, config, true)
	})

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		return nil, token.Error()
	}

	log.Println("Connected to MQTT broker:", broker)
	return client, nil
}

func getStateTopic(config Config) string {
	return fmt.Sprintf("homeassistant/binary_sensor/%s/%s/state", config.DeviceName, config.EntityID)
}

func getAvailabilityTopic(config Config) string {
	return fmt.Sprintf("homeassistant/binary_sensor/%s/%s/availability", config.DeviceName, config.EntityID)
}

func getConfigTopic(config Config) string {
	return fmt.Sprintf("homeassistant/binary_sensor/%s/%s/config", config.DeviceName, config.EntityID)
}

func publishDiscovery(client mqtt.Client, config Config) error {
	discoveryConfig := HADiscoveryConfig{
		Name:              fmt.Sprintf("%s Active", config.DeviceName),
		StateTopic:        getStateTopic(config),
		UniqueID:          fmt.Sprintf("%s_%s", config.DeviceName, config.EntityID),
		PayloadOn:         "ON",
		PayloadOff:        "OFF",
		AvailabilityTopic: getAvailabilityTopic(config),
		Device: Device{
			Identifiers:  []string{config.DeviceName},
			Name:         config.DeviceName,
			Manufacturer: "connect-idle",
			Model:        "Logind Seat Monitor",
		},
	}

	payload, err := json.Marshal(discoveryConfig)
	if err != nil {
		return err
	}

	topic := getConfigTopic(config)
	token := client.Publish(topic, 1, true, payload)
	token.Wait()
	if token.Error() != nil {
		return token.Error()
	}

	log.Println("Published Home Assistant discovery config")
	return nil
}

func publishAvailability(client mqtt.Client, config Config, available bool) {
	status := "offline"
	if available {
		status = "online"
	}
	topic := getAvailabilityTopic(config)
	client.Publish(topic, 1, true, status)
}

func publishActiveState(client mqtt.Client, config Config, idle bool) {
	// Invert: when idle is false (not idle), we're active (ON)
	state := "OFF"
	if !idle {
		state = "ON"
	}
	topic := getStateTopic(config)
	token := client.Publish(topic, 1, true, state)
	token.Wait()
	if token.Error() != nil {
		log.Printf("Error publishing state: %v", token.Error())
	} else {
		log.Printf("Published active state: %s (idle=%v)", state, idle)
	}
}

func getIdleHint(conn *dbus.Conn) (bool, error) {
	obj := conn.Object("org.freedesktop.login1", "/org/freedesktop/login1/seat/seat0")
	var idleHint bool
	err := obj.Call("org.freedesktop.DBus.Properties.Get", 0, "org.freedesktop.login1.Seat", "IdleHint").Store(&idleHint)
	if err != nil {
		return false, err
	}
	return idleHint, nil
}

func monitorIdleHint(conn *dbus.Conn, mqttClient mqtt.Client, config Config) {
	// Subscribe to PropertyChanged signals for seat0
	call := conn.BusObject().Call("org.freedesktop.DBus.AddMatch", 0,
		"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/login1/seat/seat0'")
	if call.Err != nil {
		log.Fatalf("Failed to add D-Bus match: %v", call.Err)
	}

	signals := make(chan *dbus.Signal, 10)
	conn.Signal(signals)

	// Get initial state
	idleHint, err := getIdleHint(conn)
	if err != nil {
		log.Printf("Error getting initial idle hint: %v", err)
	} else {
		log.Printf("Initial seat idle hint: %v (active: %v)", idleHint, !idleHint)
		publishActiveState(mqttClient, config, idleHint)
	}

	// Poll periodically as a backup (logind signals can be unreliable)
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	lastIdleHint := idleHint

	for {
		select {
		case sig := <-signals:
			if sig.Name == "org.freedesktop.DBus.Properties.PropertiesChanged" &&
				len(sig.Body) > 1 {
				if changes, ok := sig.Body[1].(map[string]dbus.Variant); ok {
					if idleVariant, exists := changes["IdleHint"]; exists {
						if idle, ok := idleVariant.Value().(bool); ok {
							if idle != lastIdleHint {
								log.Printf("Seat idle hint changed: %v (active: %v)", idle, !idle)
								publishActiveState(mqttClient, config, idle)
								lastIdleHint = idle
							}
						}
					}
				}
			}
		case <-ticker.C:
			// Poll current state
			currentIdle, err := getIdleHint(conn)
			if err != nil {
				log.Printf("Error polling idle hint: %v", err)
				continue
			}
			if currentIdle != lastIdleHint {
				log.Printf("Seat idle hint changed (polled): %v (active: %v)", currentIdle, !currentIdle)
				publishActiveState(mqttClient, config, currentIdle)
				lastIdleHint = currentIdle
			}
		}
	}
}

func main() {
	log.Println("Starting connect-idle - Logind Seat Active Monitor to Home Assistant bridge")

	config := loadConfig()

	// Connect to system D-Bus
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		log.Fatalf("Failed to connect to system bus: %v", err)
	}
	defer conn.Close()

	log.Println("Connected to D-Bus")

	// Connect to MQTT
	mqttClient, err := connectMQTT(config)
	if err != nil {
		log.Fatalf("Failed to connect to MQTT: %v", err)
	}
	defer mqttClient.Disconnect(250)

	// Publish Home Assistant discovery
	if err := publishDiscovery(mqttClient, config); err != nil {
		log.Fatalf("Failed to publish discovery: %v", err)
	}

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		log.Println("Shutting down...")
		publishAvailability(mqttClient, config, false)
		mqttClient.Disconnect(250)
		os.Exit(0)
	}()

	// Start monitoring
	monitorIdleHint(conn, mqttClient, config)
}
