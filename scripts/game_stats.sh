#!/usr/bin/env bash
# Polls game performance stats and writes JSON to /tmp/qs_game_stats.
# GPU: AMD RX 9060 XT via sysfs (card1).
# FPS: MangoHud CSV log from /tmp/mangohud/.
# CPU: /proc/stat diff over 0.8s.
# RAM: /proc/meminfo.
# Ping: single ICMP to 8.8.8.8.

OUT_FILE="/tmp/qs_game_stats"
MANGO_DIR="/tmp/mangohud"
GPU_BUSY="/sys/class/drm/card1/device/gpu_busy_percent"
GPU_TEMP_RAW="/sys/class/drm/card1/device/hwmon/hwmon1/temp1_input"
VRAM_USED="/sys/class/drm/card1/device/mem_info_vram_used"
VRAM_TOTAL="/sys/class/drm/card1/device/mem_info_vram_total"

echo '{"fps":0,"gpu":0,"gpu_temp":0,"cpu":0,"ram":0,"vram":0,"ping":0}' > "$OUT_FILE"

get_fps() {
    local log
    log=$(ls -t "$MANGO_DIR"/*.csv 2>/dev/null | head -1)
    [[ -z "$log" ]] && { echo 0; return; }
    local fps
    fps=$(tail -1 "$log" 2>/dev/null | cut -d',' -f1)
    [[ "$fps" =~ ^[0-9]+(\.[0-9]+)?$ ]] && printf '%d' "${fps%.*}" || echo 0
}

# Returns two space-separated values: usage% and idle_total for re-use
_cpu_sample() {
    grep "^cpu " /proc/stat | awk '{
        idle=$5
        total=$2+$3+$4+$5+$6+$7+$8
        print idle, total
    }'
}

get_cpu() {
    read -r idle1 total1 < <(_cpu_sample)
    sleep 0.8
    read -r idle2 total2 < <(_cpu_sample)
    local di=$(( idle2  - idle1  ))
    local dt=$(( total2 - total1 ))
    [[ "$dt" -le 0 ]] && { echo 0; return; }
    echo $(( (dt - di) * 100 / dt ))
}

get_ram() {
    awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{
        if (t>0) printf "%d", (t-a)*100/t; else print 0
    }' /proc/meminfo
}

get_gpu()      { cat "$GPU_BUSY"      2>/dev/null || echo 0; }
get_gpu_temp() { local t; t=$(cat "$GPU_TEMP_RAW" 2>/dev/null || echo 0); echo $(( t / 1000 )); }
get_vram()     {
    local u t
    u=$(cat "$VRAM_USED"  2>/dev/null || echo 0)
    t=$(cat "$VRAM_TOTAL" 2>/dev/null || echo 1)
    [[ "$t" -le 0 ]] && { echo 0; return; }
    echo $(( u * 100 / t ))
}

get_ping() {
    ping -c1 -W1 -q 8.8.8.8 2>/dev/null \
        | grep -oP 'rtt.*= \K[0-9.]+(?=/)' \
        | awk '{printf "%d", $1}' \
        || echo 0
}

while true; do
    fps=$(get_fps)
    gpu=$(get_gpu)
    gpu_temp=$(get_gpu_temp)
    cpu=$(get_cpu)      # includes 0.8s sleep
    ram=$(get_ram)
    vram=$(get_vram)
    ping=$(get_ping)

    printf '{"fps":%d,"gpu":%d,"gpu_temp":%d,"cpu":%d,"ram":%d,"vram":%d,"ping":%d}\n' \
        "$fps" "$gpu" "$gpu_temp" "$cpu" "$ram" "$vram" "$ping" > "$OUT_FILE"

    sleep 1
done
