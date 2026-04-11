#!/usr/bin/env fish
# Start wob (volume/brightness overlay) with PipeWire

# Create the named pipe for wob input
mkdir -p ~/.config/wob
mkfifo ~/.config/wob/wobpipe 2>/dev/null || true

# Start wob with default settings
wob < ~/.config/wob/wobpipe &

# Store the PID for cleanup
set -g wob_pid $last_pid

# Function to send volume/brightness events to wob
function send_to_wob
    echo $argv >> ~/.config/wob/wobpipe
end

# Export function for other scripts to use
functions -e send_to_wob
