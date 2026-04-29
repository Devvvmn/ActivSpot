#!/usr/bin/env bash

# Force standard C locale for number formatting (fixes printf decimal/comma issues on varying OS locales)
export LC_NUMERIC=C

# Paths
cache_dir="$HOME/.cache/quickshell/weather"
json_file="${cache_dir}/weather.json"
view_file="${cache_dir}/view_id"
daily_cache_file="${cache_dir}/daily_weather_cache.json"
next_day_cache_file="${cache_dir}/next_day_precache.json"
env_tracker_file="${cache_dir}/.env_tracker"
location_cache_file="${cache_dir}/location.json"
ENV_FILE="$(dirname "$0")/.env"

# Load environment variables robustly from .env (handles comments/whitespace/quotes)
if [ -f "$ENV_FILE" ]; then
    while IFS='=' read -r raw_key raw_val; do
        key="$(echo "$raw_key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        val="$(echo "$raw_val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -z "$key" ] && continue
        [[ "$key" =~ ^# ]] && continue
        val="${val%\"}"
        val="${val#\"}"
        export "$key=$val"
    done < "$ENV_FILE"
fi

# API Settings from .env
KEY="$OPENWEATHER_KEY"
ID="$OPENWEATHER_CITY_ID"
UNIT="${OPENWEATHER_UNIT:-metric}"
AUTO_LOCATION="${OPENWEATHER_AUTO_LOCATION:-1}"

mkdir -p "${cache_dir}"

resolved_lat=""
resolved_lon=""
resolved_tz=""
resolved_city=""

resolve_location() {
    resolved_lat=""
    resolved_lon=""
    resolved_tz=""
    resolved_city=""

    if [[ "$AUTO_LOCATION" == "0" ]]; then
        return
    fi

    local ttl=1800
    local now
    now=$(date +%s)
    local fetch_needed=1

    if [ -f "$location_cache_file" ]; then
        local mtime
        mtime=$(stat -c %Y "$location_cache_file" 2>/dev/null || echo 0)
        if [ $((now - mtime)) -lt $ttl ]; then
            fetch_needed=0
        fi
    fi

    if [ "$fetch_needed" -eq 1 ] && command -v curl >/dev/null 2>&1; then
        rm -f "$location_cache_file.tmp"
        curl -sf --max-time 4 "https://ipapi.co/json/" > "$location_cache_file.tmp" 2>/dev/null || true
        if [ ! -s "$location_cache_file.tmp" ]; then
            curl -sf --max-time 4 "https://ipwho.is/" > "$location_cache_file.tmp" 2>/dev/null || true
        fi
        if [ ! -s "$location_cache_file.tmp" ]; then
            curl -sf --max-time 4 "http://ip-api.com/json/" > "$location_cache_file.tmp" 2>/dev/null || true
        fi
        if [ -s "$location_cache_file.tmp" ]; then
            mv "$location_cache_file.tmp" "$location_cache_file"
        else
            rm -f "$location_cache_file.tmp"
        fi
    fi

    if [ -f "$location_cache_file" ] && command -v jq >/dev/null 2>&1; then
        resolved_lat=$(jq -r '.latitude // .lat // empty' "$location_cache_file" 2>/dev/null)
        resolved_lon=$(jq -r '.longitude // .lon // empty' "$location_cache_file" 2>/dev/null)
        resolved_tz=$(jq -r '.timezone // empty' "$location_cache_file" 2>/dev/null)
        resolved_city=$(jq -r '.city // empty' "$location_cache_file" 2>/dev/null)
    fi
}

get_icon() {
    case $1 in
        "50d"|"50n") icon=""; quote="Mist" ;;
        "01d") icon=""; quote="Sunny" ;;
        "01n") icon=""; quote="Clear" ;;
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") icon=""; quote="Cloudy" ;;
        "09d"|"09n"|"10d"|"10n") icon=""; quote="Rainy" ;;
        "11d"|"11n") icon=""; quote="Storm" ;;
        "13d"|"13n") icon=""; quote="Snow" ;;
        *) icon=""; quote="Unknown" ;;
    esac
    echo "$icon|$quote"
}

get_hex() {
    case $1 in
        "50d"|"50n") echo "#84afdb" ;;
        "01d") echo "#f9e2af" ;;
        "01n") echo "#cba6f7" ;;
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") echo "#bac2de" ;;
        "09d"|"09n"|"10d"|"10n") echo "#74c7ec" ;;
        "11d"|"11n") echo "#f9e2af" ;;
        "13d"|"13n") echo "#cdd6f4" ;;
        *) echo "#cdd6f4" ;;
    esac
}

write_dummy_data() {
    reason="${1:-No API Key}"
    final_json="["
    for i in {0..4}; do
        future_date=$(date -d "+$i days")
        f_day=$(date -d "$future_date" "+%a")
        f_full_day=$(date -d "$future_date" "+%A")
        f_date_num=$(date -d "$future_date" "+%d %b")

        final_json="${final_json} {
            \"id\": \"${i}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"max\": \"0.0\",
            \"min\": \"0.0\",
            \"feels_like\": \"0.0\",
            \"wind\": \"0\",
            \"humidity\": \"0\",
            \"pop\": \"0\",
            \"icon\": \"\",
            \"hex\": \"#cdd6f4\",
            \"desc\": \"${reason}\",
            \"hourly\": [{\"time\": \"00:00\", \"temp\": \"0.0\", \"icon\": \"\", \"hex\": \"#cdd6f4\"}]
        },"
    done
    final_json="${final_json%,}]"
    echo "{ \"forecast\": ${final_json} }" > "${json_file}"
}

get_data() {
    resolve_location
    local target_tz="${resolved_tz:-}"
    if [ -z "$target_tz" ]; then
        target_tz=$(timedatectl show -p Timezone --value 2>/dev/null)
    fi
    if [ -z "$target_tz" ]; then
        target_tz="UTC"
    fi

    # ---------------------------------------------------------
    # DUMMY DATA FALLBACK (If API key is missing or skipped)
    # ---------------------------------------------------------
    if [[ -z "$KEY" || "$KEY" == "Skipped" || "$KEY" == "OPENWEATHER_KEY" ]]; then
        write_dummy_data "No API Key"
        return
    fi

    # ---------------------------------------------------------
    # STANDARD API FETCH LOGIC
    # ---------------------------------------------------------
    if [ -n "$resolved_lat" ] && [ -n "$resolved_lon" ]; then
        forecast_url="https://api.openweathermap.org/data/2.5/forecast?APPID=${KEY}&lat=${resolved_lat}&lon=${resolved_lon}&units=${UNIT}"
    else
        if [ -z "$ID" ]; then
            write_dummy_data "Location unavailable"
            return
        fi
        forecast_url="https://api.openweathermap.org/data/2.5/forecast?APPID=${KEY}&id=${ID}&units=${UNIT}"
    fi

    # Do not use curl -f here; we need API error JSON bodies (401/429/etc).
    raw_api=$(curl -s --max-time 10 "$forecast_url")

    api_cod=$(echo "$raw_api" | jq -r '.cod // empty' 2>/dev/null)
    api_msg=$(echo "$raw_api" | jq -r '.message // empty' 2>/dev/null)
    if [ -z "$raw_api" ]; then
        write_dummy_data "Weather fetch failed (network)"
        return
    fi
    if [[ "$api_cod" != "200" ]]; then
        if [ -n "$api_msg" ]; then
            write_dummy_data "Weather API: ${api_msg}"
        else
            write_dummy_data "Weather fetch failed"
        fi
        return
    fi

    current_date=$(TZ="$target_tz" date +%Y-%m-%d)
    tomorrow_date=$(TZ="$target_tz" date -d "tomorrow" +%Y-%m-%d)

    # 1. ROLLOVER CHECK
    if [ -f "$next_day_cache_file" ]; then
        precache_date=$(cat "$next_day_cache_file" | jq -r '.[0].dt_txt' | cut -d' ' -f1)
        if [ "$precache_date" == "$current_date" ]; then
            mv "$next_day_cache_file" "$daily_cache_file"
        fi
    fi

    # 2. PROCESS TODAY
    api_today_items=$(echo "$raw_api" | jq -c ".list[] | select(.dt_txt | startswith(\"$current_date\"))" | jq -s '.')

    if [ -f "$daily_cache_file" ]; then
        cached_date=$(cat "$daily_cache_file" | jq -r '.[0].dt_txt' | cut -d' ' -f1)
        if [ "$cached_date" == "$current_date" ]; then
            merged_today=$(echo "$api_today_items" | jq --slurpfile cache "$daily_cache_file" \
                '($cache[0] + .) | unique_by(.dt) | sort_by(.dt)')
        else
            merged_today="$api_today_items"
        fi
    else
        merged_today="$api_today_items"
    fi

    echo "$merged_today" > "$daily_cache_file"

    # 3. PRE-CACHE TOMORROW
    api_tomorrow_items=$(echo "$raw_api" | jq -c ".list[] | select(.dt_txt | startswith(\"$tomorrow_date\"))" | jq -s '.')
    echo "$api_tomorrow_items" > "$next_day_cache_file"

    # 4. BUILD FINAL JSON
    processed_forecast=$(echo "$raw_api" | jq --argjson today "$merged_today" --arg date "$current_date" \
        '.list = ($today + [.list[] | select(.dt_txt | startswith($date) | not)])')

    if [ ! -z "$processed_forecast" ]; then
        dates=$(echo "$processed_forecast" | jq -r '.list[].dt_txt | split(" ")[0]' | uniq | head -n 5)

        final_json="["
        counter=0

        for d in $dates; do
            day_data=$(echo "$processed_forecast" | jq "[.list[] | select(.dt_txt | startswith(\"$d\"))]")

            raw_max=$(echo "$day_data" | jq '[.[].main.temp_max] | max')
            f_max_temp=$(printf "%.1f" "$raw_max")

            raw_min=$(echo "$day_data" | jq '[.[].main.temp_min] | min')
            f_min_temp=$(printf "%.1f" "$raw_min")

            raw_feels=$(echo "$day_data" | jq '[.[].main.feels_like] | max')
            f_feels_like=$(printf "%.1f" "$raw_feels")

            f_pop=$(echo "$day_data" | jq '[.[].pop] | max')
            f_pop_pct=$(echo "$f_pop * 100" | bc | cut -d. -f1)
            f_wind=$(echo "$day_data" | jq '[.[].wind.speed] | max | round')
            f_hum=$(echo "$day_data" | jq '[.[].main.humidity] | add / length | round')

            f_code=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].icon')
            f_desc=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].description' | sed -e "s/\b\(.\)/\u\1/g")
            f_icon_data=$(get_icon "$f_code")
            f_icon=$(echo "$f_icon_data" | cut -d'|' -f1)
            f_hex=$(get_hex "$f_code")

            f_day=$(TZ="$target_tz" date -d "$d" "+%a")
            f_full_day=$(TZ="$target_tz" date -d "$d" "+%A")
            f_date_num=$(TZ="$target_tz" date -d "$d" "+%d %b")

            hourly_json="["
            count_slots=$(echo "$day_data" | jq '. | length')
            count_slots=$((count_slots-1))

            for i in $(seq 0 1 $count_slots); do
                slot_item=$(echo "$day_data" | jq ".[$i]")

                raw_s_temp=$(echo "$slot_item" | jq ".main.temp")
                s_temp=$(printf "%.1f" "$raw_s_temp")

                s_dt=$(echo "$slot_item" | jq ".dt")
                s_time=$(TZ="$target_tz" date -d @"$s_dt" "+%H:%M")
                s_code=$(echo "$slot_item" | jq -r ".weather[0].icon")
                s_hex=$(get_hex "$s_code")
                s_icon=$(get_icon "$s_code" | cut -d'|' -f1)

                hourly_json="${hourly_json} {\"time\": \"${s_time}\", \"temp\": \"${s_temp}\", \"icon\": \"${s_icon}\", \"hex\": \"${s_hex}\"},"
            done
            hourly_json="${hourly_json%,}]"

            final_json="${final_json} {
                \"id\": \"${counter}\",
                \"day\": \"${f_day}\",
                \"day_full\": \"${f_full_day}\",
                \"date\": \"${f_date_num}\",
                \"max\": \"${f_max_temp}\",
                \"min\": \"${f_min_temp}\",
                \"feels_like\": \"${f_feels_like}\",
                \"wind\": \"${f_wind}\",
                \"humidity\": \"${f_hum}\",
                \"pop\": \"${f_pop_pct}\",
                \"icon\": \"${f_icon}\",
                \"hex\": \"${f_hex}\",
                \"desc\": \"${f_desc}\",
                \"hourly\": ${hourly_json}
            },"
            ((counter++))
        done
        final_json="${final_json%,}]"

        city_name=$(echo "$raw_api" | jq -r '.city.name // empty')
        if [ -z "$city_name" ] && [ -n "$resolved_city" ]; then
            city_name="$resolved_city"
        fi

        echo "{ \"forecast\": ${final_json}, \"meta\": { \"timezone\": \"${target_tz}\", \"city\": \"${city_name}\" } }" > "${json_file}"
    fi
}

# --- MODE HANDLING ---
if [[ "$1" == "--getdata" ]]; then
    get_data

elif [[ "$1" == "--json" ]]; then
    CACHE_LIMIT=900
    PENDING_RETRY_LIMIT=3600

    env_changed=0
    if [ -f "$ENV_FILE" ]; then
        env_mtime=$(stat -c %Y "$ENV_FILE")
        last_env_mtime=$(cat "$env_tracker_file" 2>/dev/null || echo "0")
        if [ "$env_mtime" -gt "$last_env_mtime" ]; then
            env_changed=1
            echo "$env_mtime" > "$env_tracker_file"
        fi
    fi

    if [ -f "$json_file" ]; then
        file_time=$(stat -c %Y "$json_file")
        current_time=$(date +%s)
        diff=$((current_time - file_time))

        if [ "$env_changed" -eq 1 ]; then
            get_data
        elif grep -q '"desc": "No API Key"\|"desc": "Weather API:\|"desc": "Weather fetch failed"\|"desc": "Location unavailable"' "$json_file"; then
            # Any fallback/error payload — refresh immediately so UI can recover
            get_data
        else
            if [ $diff -gt $CACHE_LIMIT ]; then
                touch "$json_file"
                get_data &
            fi
        fi
        cat "$json_file"
    else
        get_data
        cat "$json_file"
    fi

elif [[ "$1" == "--view-listener" ]]; then
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
    tail -F "$view_file"

elif [[ "$1" == "--nav" ]]; then
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
    current=$(cat "$view_file")
    direction=$2
    max_idx=4
    if [[ "$direction" == "next" ]]; then
        if [ "$current" -lt "$max_idx" ]; then
            new=$((current + 1))
            echo "$new" > "$view_file"
        fi
    elif [[ "$direction" == "prev" ]]; then
        if [ "$current" -gt 0 ]; then
            new=$((current - 1))
            echo "$new" > "$view_file"
        fi
    fi

elif [[ "$1" == "--icon" ]]; then
    cat "$json_file" | jq -r '.forecast[0].icon'

elif [[ "$1" == "--temp" ]]; then
    t=$(cat "$json_file" | jq -r '.forecast[0].max')
    echo "${t}°C"

elif [[ "$1" == "--hex" ]]; then
    cat "$json_file" | jq -r '.forecast[0].hex'

elif [[ "$1" == "--timezone" ]]; then
    resolve_location
    if [ -n "$resolved_tz" ]; then
        echo "$resolved_tz"
    else
        timedatectl show -p Timezone --value 2>/dev/null || echo "UTC"
    fi

elif [[ "$1" == "--current-icon" ]]; then
    curr_time=$(date +%H:%M)
    cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .icon'

elif [[ "$1" == "--current-temp" ]]; then
    curr_time=$(date +%H:%M)
    t=$(cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .temp')
    echo "${t}°C"

elif [[ "$1" == "--current-hex" ]]; then
    curr_time=$(date +%H:%M)
    cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .hex'
fi
