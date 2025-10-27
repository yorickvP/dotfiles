# connect-idle

A Go service that monitors systemd-logind's idle hint and publishes it to Home Assistant via MQTT as a binary sensor.

## Features

- Monitors systemd-logind IdleHint property via D-Bus
- Publishes idle state to Home Assistant via MQTT
- Automatic Home Assistant MQTT discovery
- Configurable via environment variables
- Graceful shutdown with availability tracking
- Automatic reconnection to MQTT broker

## Prerequisites

- Go 1.21 or later
- systemd-logind (standard on most Linux systems)
- MQTT broker (e.g., Mosquitto)
- Home Assistant with MQTT integration configured

## Installation

### Build from source

```bash
git clone <your-repo>
cd connect-idle
go build -o connect-idle
```

### Run directly

```bash
go run main.go
```

## Configuration

Configure via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `MQTT_BROKER` | MQTT broker hostname | `localhost` |
| `MQTT_PORT` | MQTT broker port | `1883` |
| `MQTT_USER` | MQTT username (optional) | - |
| `MQTT_PASSWORD` | MQTT password (optional) | - |
| `MQTT_CLIENT_ID` | MQTT client ID | `connect-idle` |
| `DEVICE_NAME` | Device name for Home Assistant | System hostname |
| `ENTITY_ID` | Entity ID suffix | `idle_hint` |

### Example

```bash
export MQTT_BROKER="192.168.1.100"
export MQTT_USER="homeassistant"
export MQTT_PASSWORD="your-password"
./connect-idle
```

## Home Assistant Integration

The service automatically registers itself with Home Assistant using MQTT discovery. After starting the service, you'll find a new binary sensor:

- Entity: `binary_sensor.<device_name>_idle_hint`
- State: `ON` when system is idle, `OFF` when active

### Example Automation

```yaml
automation:
  - alias: "Dim lights when idle"
    trigger:
      - platform: state
        entity_id: binary_sensor.your_hostname_idle_hint
        to: "on"
        for: "00:05:00"
    action:
      - service: light.turn_off
        target:
          entity_id: light.desk_lamp
```

## How It Works

1. Connects to systemd-logind via D-Bus
2. Monitors the `IdleHint` property on `/org/freedesktop/login1`
3. Publishes state changes to MQTT
4. Polls every 30 seconds as a backup (logind signals can be unreliable)
5. Sends availability status for Home Assistant offline detection

## Systemd Service

Create `/etc/systemd/system/connect-idle.service`:

```ini
[Unit]
Description=Connect Idle - Logind to Home Assistant Bridge
After=network-online.target

[Service]
Type=simple
User=%i
ExecStart=/usr/local/bin/connect-idle
Restart=always
RestartSec=10
Environment="MQTT_BROKER=192.168.1.100"
Environment="MQTT_USER=homeassistant"
Environment="MQTT_PASSWORD=your-password"

[Install]
WantedBy=default.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable connect-idle@$USER.service
sudo systemctl start connect-idle@$USER.service
```

## Idle Detection

The systemd-logind idle hint is typically set by:
- Desktop environments (GNOME, KDE, etc.)
- Display managers
- Manual configuration via `systemd-inhibit` or `loginctl set-idle-hint`

Check current idle status:

```bash
loginctl show-session $XDG_SESSION_ID --property=IdleHint
```

## Troubleshooting

### Check D-Bus connection

```bash
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager IdleHint
```

### Monitor D-Bus signals

```bash
dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='/org/freedesktop/login1'"
```

### MQTT messages

Subscribe to all topics:

```bash
mosquitto_sub -h localhost -t "homeassistant/binary_sensor/#" -v
```

## License

MIT
