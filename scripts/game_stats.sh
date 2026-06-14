#!/usr/bin/env bash
# Polls game performance stats and writes JSON to /tmp/qs_game_stats.
# GPU: auto-detects AMD (sysfs) or NVIDIA (nvidia-smi).
# FPS: MangoHud CSV log from /tmp/mangohud/.
# CPU: /proc/stat diff over 0.8s.
# RAM/VRAM: /proc/meminfo + sysfs/nvidia-smi.
# Ping: single ICMP to 8.8.8.8.

OUT_FILE="/tmp/qs_game_stats"
MANGO_DIR="/tmp/mangohud"
mkdir -p "$MANGO_DIR"

echo '{"fps":0,"gpu":0,"gpu_temp":0,"cpu":0,"ram":0,"vram":0,"ping":0}' > "$OUT_FILE"

# ── GPU detection ─────────────────────────────────────────────────────────

GPU_VENDOR=""
AMD_CARD_PATH=""
AMD_HWMON_PATH=""

detect_gpu() {
    # NVIDIA: check if nvidia-smi is available and responsive
    if command -v nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null; then
        GPU_VENDOR="nvidia"
        return
    fi

    # AMD: find the first render card with gpu_busy_percent
    for card in /sys/class/drm/card[0-9]*/device; do
        [[ -f "$card/gpu_busy_percent" ]] || continue
        AMD_CARD_PATH="$card"
        # Find the hwmon subdirectory with temp1_input
        for hw in "$card"/hwmon/hwmon[0-9]*; do
            [[ -f "$hw/temp1_input" ]] && AMD_HWMON_PATH="$hw" && break
        done
        GPU_VENDOR="amd"
        return
    done

    GPU_VENDOR="none"
}

detect_gpu

# ── GPU stat functions ────────────────────────────────────────────────────

get_gpu() {
    case "$GPU_VENDOR" in
        amd)    cat "$AMD_CARD_PATH/gpu_busy_percent" 2>/dev/null || echo 0 ;;
        nvidia) nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo 0 ;;
        *)      echo 0 ;;
    esac
}

get_gpu_temp() {
    case "$GPU_VENDOR" in
        amd)
            local t; t=$(cat "$AMD_HWMON_PATH/temp1_input" 2>/dev/null || echo 0)
            echo $(( t / 1000 ))
            ;;
        nvidia)
            nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo 0
            ;;
        *) echo 0 ;;
    esac
}

get_vram() {
    case "$GPU_VENDOR" in
        amd)
            local u t
            u=$(cat "$AMD_CARD_PATH/mem_info_vram_used"  2>/dev/null || echo 0)
            t=$(cat "$AMD_CARD_PATH/mem_info_vram_total" 2>/dev/null || echo 1)
            [[ "$t" -le 0 ]] && { echo 0; return; }
            echo $(( u * 100 / t ))
            ;;
        nvidia)
            # outputs "used [MiB], total [MiB]"
            nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null \
                | head -1 \
                | awk -F',' '{u=$1+0; t=$2+0; if(t>0) printf "%d", u*100/t; else print 0}'
            ;;
        *) echo 0 ;;
    esac
}

# ── Universal stat functions ──────────────────────────────────────────────

get_fps() {
    local log
    log=$(ls -t "$MANGO_DIR"/*.csv 2>/dev/null | head -1)
    [[ -z "$log" ]] && { echo 0; return; }
    local fps
    fps=$(tail -1 "$log" 2>/dev/null | cut -d',' -f1)
    [[ "$fps" =~ ^[0-9]+(\.[0-9]+)?$ ]] && printf '%d' "${fps%.*}" || echo 0
}

_cpu_sample() {
    grep "^cpu " /proc/stat | awk '{
        idle=$5; total=$2+$3+$4+$5+$6+$7+$8; print idle, total
    }'
}

get_cpu() {
    read -r idle1 total1 < <(_cpu_sample)
    sleep 0.8
    read -r idle2 total2 < <(_cpu_sample)
    local di=$(( idle2 - idle1 ))
    local dt=$(( total2 - total1 ))
    [[ "$dt" -le 0 ]] && { echo 0; return; }
    echo $(( (dt - di) * 100 / dt ))
}

get_ram() {
    awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{
        if (t>0) printf "%d", (t-a)*100/t; else print 0
    }' /proc/meminfo
}

get_ping() {
    ping -c1 -W1 -q 8.8.8.8 2>/dev/null \
        | grep -oP 'rtt.*= \K[0-9.]+(?=/)' \
        | awk '{printf "%d", $1}' \
        || echo 0
}

# ── Main loop ─────────────────────────────────────────────────────────────

while true; do
    fps=$(get_fps)
    gpu=$(get_gpu)
    gpu_temp=$(get_gpu_temp)
    cpu=$(get_cpu)
    ram=$(get_ram)
    vram=$(get_vram)
    ping_ms=$(get_ping)

    printf '{"fps":%d,"gpu":%d,"gpu_temp":%d,"cpu":%d,"ram":%d,"vram":%d,"ping":%d}\n' \
        "$fps" "$gpu" "$gpu_temp" "$cpu" "$ram" "$vram" "$ping_ms" > "$OUT_FILE"

    sleep 1
done
