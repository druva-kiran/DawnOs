#!/usr/bin/env bash
# Continuous stream of media metadata using playerctl
# Replaces empty strings or non-existent metadata gracefully
exec playerctl -F metadata --format '{"title": "{{title}}", "artist": "{{artist}}", "artUrl": "{{mpris:artUrl}}", "status": "{{status}}"}' 2>/dev/null
