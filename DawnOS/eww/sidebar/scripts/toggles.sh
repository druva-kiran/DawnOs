#!/usr/bin/env bash
if [[ "$1" == "wifi" ]]; then
    kitty --class floating_impala -e impala &
elif [[ "$1" == "bluetooth" ]]; then
    kitty --class floating_bluetui -e bluetui &
elif [[ "$1" == "nightlight" ]]; then
    if pgrep -x "hyprsunset" > /dev/null; then
        pkill hyprsunset
    else
        hyprsunset -t 4000 &
    fi
elif [[ "$1" == "screenshot" ]]; then
    hyprshot -m region  
fi
