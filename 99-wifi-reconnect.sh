#!/bin/bash
INTERFACE="$1"
STATUS="$2"
LAST_FILE="/tmp/last_wifi_connection"
LOG_FILE="/var/log/nm-reconnect.log"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/nm-reconnect.log"
MAX_SESSIONS=3

nmcli_result() {
    case "$1" in
        0) echo "0 (Success)" ;;
        1) echo "1 (Unknown error)" ;;
        2) echo "2 (Invalid parameters)" ;;
        3) echo "3 (Timeout)" ;;
        4) echo "4 (Connection activation failed)" ;;
        5) echo "5 (Connection deactivation failed)" ;;
        6) echo "6 (Disconnect failed)" ;;
        7) echo "7 (Connection delete failed)" ;;
        8) echo "8 (NetworkManager not running)" ;;
        *) echo "$1 (Unknown code)" ;;
    esac
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [PID $$] - $1" >> "$LOG_FILE"
}

rotate_log() {
    if [[ ! -f "$LOG_FILE" ]]; then return; fi
    local session_lines
    session_lines=$(grep -n "=== SESSION" "$LOG_FILE" | tail -n $((MAX_SESSIONS - 1)) | head -1 | cut -d: -f1)
    if [[ -n "$session_lines" ]]; then
        sed -i "1,$((session_lines - 1))d" "$LOG_FILE"
    fi
}

TYPE=$(nmcli -t -f DEVICE,TYPE device | awk -F: -v dev="$INTERFACE" '$1==dev {print $2}')
[[ "$TYPE" != "wifi" ]] && exit 0

log "Triggered: INTERFACE=$INTERFACE STATUS=$STATUS"

if [[ "$STATUS" == "up" ]]; then
    SSID=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2}')
    echo "$SSID" > "$LAST_FILE"
    log "Connected to: $SSID"
    exit 0
fi

if [[ "$STATUS" == "down" ]]; then
    exec 9>/tmp/nm-reconnect.lock
    flock -n 9 || exit 0

    if nmcli -t -f STATE general | grep -q "^connected$"; then
        log "STATUS=down received but already connected, skipping."
        exit 0
    fi

    rotate_log
    log "=== SESSION START ==="

    LAST_CONNECTION=$(cat "$LAST_FILE" 2>/dev/null)
    log "Connection lost. Last SSID: ${LAST_CONNECTION:-unknown}"

    while ! nmcli -t -f STATE general | grep -q "^connected$"; do
        nmcli dev wifi rescan 2>/dev/null
        sleep 5

        if [[ -n "$LAST_CONNECTION" ]]; then
            if nmcli -t -f SSID dev wifi list | grep -Fxq "$LAST_CONNECTION"; then
                log "SSID found — attempting reconnect..."
                nmcli connection up "$LAST_CONNECTION" 2>/dev/null
                log "Reconnect result: $(nmcli_result $?)"
            else
                log "SSID not visible yet, rescanning..."
            fi
        else
            log "No saved SSID — connecting to best available..."
            nmcli device connect "$INTERFACE" 2>/dev/null
            log "Device connect result: $(nmcli_result $?)"
        fi

        CONNECTIVITY=$(nmcli -t -f CONNECTIVITY general)
        sleep 5
        nmcli networking connectivity check >/dev/null 2>&1
        CONNECTIVITY_AFTER=$(nmcli -t -f CONNECTIVITY general)
        log "Connectivity check: $CONNECTIVITY → $CONNECTIVITY_AFTER"
        sleep 10
    done

    log "Reconnected successfully!"
    log "=== SESSION END ==="
fi

exit 0
