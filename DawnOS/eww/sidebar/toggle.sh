#!/bin/bash

# Toggle sidebar visibility using state file
STATE_FILE="/tmp/eww_sidebar_state"

if [ -f "$STATE_FILE" ]; then
  # Sidebar is open, close it
  eww close sidebar
  rm "$STATE_FILE"
else
  # Sidebar is closed, open it
  eww open sidebar
  touch "$STATE_FILE"
fi
