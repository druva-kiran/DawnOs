#!/usr/bin/env bash
if [[ "$1" == "up" ]]; then
    brightnessctl set 5%+
elif [[ "$1" == "down" ]]; then
    brightnessctl set 5%-
elif [[ "$1" == "set" ]]; then
    val=$(printf "%.0f" "$2")
    brightnessctl set "${val}%"
else
    # get brightness
    get_val=$(brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}')
    echo "$get_val"
fi
