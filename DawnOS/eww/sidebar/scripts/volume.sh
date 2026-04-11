#!/usr/bin/env bash
if [[ "$1" == "up" ]]; then
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
elif [[ "$1" == "down" ]]; then
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
elif [[ "$1" == "set" ]]; then
    val=$(printf "%.0f" "$2")
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${val}%"
elif [[ "$1" == "mute" ]]; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
else
    # get volume
    vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    if [[ $vol == *"MUTED"* ]]; then
        echo "0"
    else
        echo "$vol" | awk '{print int($2 * 100)}'
    fi
fi
