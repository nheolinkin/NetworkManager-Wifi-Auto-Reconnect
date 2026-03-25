<meta name="google-site-verification" content="eo_b1xV27spOjQRyCrBy2xkRx9D37z1fpF5tve-bA4o" />

[![English](https://img.shields.io/badge/Language-English-blue?style=flat)](README.md)
[![Tiếng Việt](https://img.shields.io/badge/Ngôn%20ngữ-Tiếng%20Việt-red?style=flat)](README.vi.md)
# 📶 NetworkManager WiFi Auto-Reconnect

Một dispatcher script cho NetworkManager trên Linux, tự động kết nối lại WiFi khi mất mạng — tương tự như cách smartphone xử lý việc kết nối lại mạng.

[![View on GitHub](https://img.shields.io/badge/View%20on-GitHub-181717?style=flat&logo=github)](https://github.com/nheolinkin/NetworkManager-Wifi-Auto-Reconnect)

---

## ✨ Tính năng

- 🔄 **Tự động kết nối lại** mạng WiFi đã lưu khi mất kết nối
- 📡 **Chờ SSID xuất hiện** trước khi thử kết nối lại (xử lý trường hợp router khởi động lại)
- 🔒 **Tránh chạy nhiều instance** cùng lúc bằng file locking (`flock`)
- 📝 **Ghi log chi tiết** với session rotation (giữ lại 3 session gần nhất)
- 🌐 **Kiểm tra kết nối** sau khi reconnect để fix icon `?` trên thanh trạng thái
- 🛡️ **Chỉ xử lý WiFi** — bỏ qua Ethernet, VPN và các interface khác
- ⚡ **Bỏ qua** nếu đã có mạng khi được trigger

---

## 📋 Yêu cầu

- Linux với **NetworkManager**
- `bash`, `nmcli`, `flock` (có sẵn trên hầu hết các distro)
- Đã test trên **Fedora 43 + GNOME 49**

---

## 🚀 Cài đặt

### 1. Tải script về máy

```bash
curl -o /tmp/99-wifi-reconnect.sh https://raw.githubusercontent.com/nheolinkin/NetworkManager-Wifi-Auto-Reconnect/refs/heads/main/99-wifi-reconnect.sh
```

Hoặc clone repo:

```bash
git clone https://github.com/nheolinkin/NetworkManager-Wifi-Auto-Reconnect.git
```

### 2. Copy vào thư mục dispatcher của NetworkManager

```bash
sudo cp 99-wifi-reconnect.sh /etc/NetworkManager/dispatcher.d/99-wifi-reconnect.sh
```

### 3. Cấp quyền thực thi

```bash
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-wifi-reconnect.sh
sudo chown root:root /etc/NetworkManager/dispatcher.d/99-wifi-reconnect.sh
```

### 4. Khởi động lại NetworkManager

```bash
sudo systemctl restart NetworkManager
```

---

## 📖 Cách hoạt động

| Sự kiện | Hành động |
|---|---|
| WiFi `up` | Lưu SSID hiện tại vào `/tmp/last_wifi_connection` |
| WiFi `down` | Bắt đầu vòng lặp reconnect |
| Chưa thấy SSID | Rescan mỗi ~20 giây và chờ |
| Thấy SSID | Thử kết nối lại đúng mạng đã lưu |
| Không có SSID đã lưu | Kết nối vào mạng tốt nhất hiện có |
| Kết nối thành công | Trigger connectivity check để fix icon trạng thái |

### Thời gian mỗi vòng lặp reconnect

```
rescan → chờ 5s → thử kết nối → chờ 5s → kiểm tra connectivity → chờ 10s → lặp lại
```

Tổng cộng ~20 giây mỗi chu kỳ, lặp vô hạn cho đến khi kết nối thành công.

---

## 📝 Log

Log được lưu tại `/var/log/nm-reconnect.log` (fallback về `/tmp/nm-reconnect.log` nếu không có quyền ghi).

Chỉ giữ lại **3 session gần nhất** để tránh tốn dung lượng.

### Theo dõi log realtime

```bash
tail -F /var/log/nm-reconnect.log
```

### Ví dụ log

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

## 🔧 Cấu hình

Chỉnh sửa các biến sau ở đầu script để tùy chỉnh:

| Biến | Mặc định | Mô tả |
|---|---|---|
| `LAST_FILE` | `/tmp/last_wifi_connection` | File lưu SSID đã kết nối gần nhất |
| `LOG_FILE` | `/var/log/nm-reconnect.log` | Đường dẫn file log |
| `MAX_SESSIONS` | `3` | Số session giữ lại trong log |

---

## 🗑️ Gỡ cài đặt

```bash
sudo rm /etc/NetworkManager/dispatcher.d/99-wifi-reconnect.sh
sudo rm -f /tmp/last_wifi_connection /tmp/nm-reconnect.lock
sudo rm -f /var/log/nm-reconnect.log
sudo systemctl restart NetworkManager
```

---

## 📜 Giấy phép

MIT License — tự do sử dụng, chỉnh sửa và phân phối.
