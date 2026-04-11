#!/usr/bin/env zsh


# Kill already running waybar instances and swaync
pkill waybar
pkill swaync

# Start Waybar in the background and swaync
waybar &
swaync &

# Reload Swaync's configuration and CSS *without* killing it
swaync-client -R  # Reloads config
swaync-client -rs # Reloads CSS
