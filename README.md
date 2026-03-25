<meta name="google-site-verification" content="eo_b1xV27spOjQRyCrBy2xkRx9D37z1fpF5tve-bA4o" />

[![English](https://img.shields.io/badge/Language-English-blue?style=flat)](README.md)
[![Tiếng Việt](https://img.shields.io/badge/Ngôn%20ngữ-Tiếng%20Việt-red?style=flat)](README.vi.md)
# 📶 NetworkManager WiFi Auto-Reconnect

A NetworkManager dispatcher script for Linux that automatically reconnects to WiFi when the connection drops — similar to how smartphones handle network reconnection.

[![View on GitHub](https://img.shields.io/badge/View%20on-GitHub-181717?style=flat&logo=github)](https://github.com/nheolinkin/NetworkManager-Wifi-Auto-Reconnect)
---

## ✨ Features

- 🔄 **Auto-reconnect** to the last known WiFi network when connection drops
- 📡 **Waits for SSID** to reappear before attempting reconnect (handles router reboots)
- 🔒 **Prevents duplicate instances** using file locking (`flock`)
- 📝 **Detailed logging** with session rotation (keeps last 3 sessions)
- 🌐 **Connectivity check** after reconnect to fix the `?` icon on the status bar
- 🛡️ **WiFi-only** — ignores Ethernet, VPN and other interfaces
- ⚡ **Skips reconnect** if already connected when triggered

---

## 📋 Requirements

- Linux with **NetworkManager**
- `bash`, `nmcli`, `flock` (available by default on most distros)
- Tested on **Fedora 43 + GNOME 49**

---

## 🚀 Installation

### 1. Download the script

```bash
curl -o /tmp/99-wifi-reconnect.sh https://raw.githubusercontent.com/nheolinkin/NetworkManager-Wifi-Auto-Reconnect/refs/heads/main/99-wifi-reconnect.sh
```

Or clone the repo:

```bash
git clone https://github.com/nheolinkin/NetworkManager-Wifi-Auto-Reconnect.git
```

### 2. Copy to NetworkManager dispatcher directory

```bash
sudo cp 99-wifi-reconnect.sh /etc/NetworkManager/dispatcher.d/99-wifi-reconnect.sh
```

### 3. Set correct permissions

```bash
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-wifi-reconnect.sh
sudo chown root:root /etc/NetworkManager/dispatcher.d/99-wifi-reconnect.sh
```

### 4. Restart NetworkManager

```bash
sudo systemctl restart NetworkManager
```

---

## 📖 How It Works

| Event | Action |
|---|---|
| WiFi `up` | Saves current SSID to `/tmp/last_wifi_connection` |
| WiFi `down` | Starts reconnect loop |
| SSID not visible | Rescans every ~20 seconds and waits |
| SSID found | Attempts to reconnect to saved SSID |
| No saved SSID | Connects to best available network |
| Reconnected | Triggers connectivity check to fix status icon |

### Reconnect loop timing

```
rescan → sleep 5s → attempt connect → sleep 5s → connectivity check → sleep 10s → repeat
```

Total: ~20 seconds per retry cycle, loops indefinitely until connected.

---

## 📝 Logs

Logs are saved to `/var/log/nm-reconnect.log` (falls back to `/tmp/nm-reconnect.log` if permission denied).

Only the last **3 sessions** are kept to avoid excessive disk usage.

### Monitor logs in real-time

```bash
tail -F /var/log/nm-reconnect.log
```

### Example log output

```
2026-03-17 20:14:55 [PID 601977] - === SESSION START ===
2026-03-17 20:14:55 [PID 601977] - Connection lost. Last SSID: MyWiFi
2026-03-17 20:15:00 [PID 601977] - SSID not visible yet, rescanning...
2026-03-17 20:15:20 [PID 601977] - SSID not visible yet, rescanning...
2026-03-17 20:16:00 [PID 601977] - SSID found — attempting reconnect...
2026-03-17 20:16:13 [PID 601977] - Reconnect result: 0 (Success)
2026-03-17 20:16:39 [PID 601977] - Connectivity check: none → full
2026-03-17 20:16:49 [PID 601977] - Reconnected successfully!
2026-03-17 20:16:49 [PID 601977] - === SESSION END ===
```

---

## 🔧 Configuration

Edit the following variables at the top of the script to customize behavior:

| Variable | Default | Description |
|---|---|---|
| `LAST_FILE` | `/tmp/last_wifi_connection` | File to store last connected SSID |
| `LOG_FILE` | `/var/log/nm-reconnect.log` | Log file path |
| `MAX_SESSIONS` | `3` | Number of sessions to keep in log |

---

## 🗑️ Uninstall

```bash
sudo rm /etc/NetworkManager/dispatcher.d/99-wifi-reconnect.sh
sudo rm -f /tmp/last_wifi_connection /tmp/nm-reconnect.lock
sudo rm -f /var/log/nm-reconnect.log
sudo systemctl restart NetworkManager
```

---

## 📜 License

MIT License — free to use, modify and distribute.
