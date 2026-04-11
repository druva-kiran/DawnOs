#!/bin/bash

# Configuration
EWW_CMD="eww -c $HOME/.config/eww/visualizer"
WINDOW_NAME="visualizer_win"
IS_OPEN=false

# Cleanup function to close the visualizer when the script exits
cleanup() {
    $EWW_CMD close $WINDOW_NAME >/dev/null 2>&1
    exit 0
}

trap cleanup SIGINT SIGTERM

while true; do
    # Check if audio is playing using pactl or playerctl
    if pactl list sink-inputs 2>/dev/null | grep -qi "state: running" || playerctl status 2>/dev/null | grep -qi "playing"; then
        if ! $IS_OPEN; then
            $EWW_CMD open $WINDOW_NAME
            IS_OPEN=true
        fi
    else
        if $IS_OPEN; then
            $EWW_CMD close $WINDOW_NAME
            IS_OPEN=false
        fi
    fi
    sleep 1
done
