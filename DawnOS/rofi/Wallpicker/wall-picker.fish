#!/usr/bin/env fish

# 1. Setup paths
set WALL_DIR "$HOME/Wallpapers"

if not test -d "$WALL_DIR"
    echo "Directory $WALL_DIR does not exist. Fix your paths."
    exit 1
end

# 2. Feed the images into Rofi
set SELECTED (for pic in $WALL_DIR/*
    if test -f "$pic"
        set filename (basename "$pic")
        printf "%s\0icon\x1f%s\n" $filename $pic
    end
end | rofi -dmenu -i -p "Wallpaper" -show-icons -theme ~/.config/rofi/Wallpicker/theme.rasi)

# 3. If you hit escape, kill the script
if test -z "$SELECTED"
    exit 0
end

# 4. Construct the full file path
set WALLPAPER "$WALL_DIR/$SELECTED"

# 5. EXECUTION PIPELINE
# Set the actual image on the screen
awww img "$WALLPAPER" --transition-type any

# Generate the Pywal colors (cache files)
wal -i "$WALLPAPER" 

# Generate Matugen colors for GTK and QT apps
matugen image "$WALLPAPER" --source-color-index 0
pkill nautilus
killall -9 gnome-clocks

# Update swayosd colors from pywal
~/.config/swayosd/update-colors.fish

# 6. Reload UI Components
# Reload Notification Center
swaync-client -rs

# Restart swayosd to apply new CSS
pkill -f swayosd-server
sleep 0.3
swayosd-server --config ~/.config/swayosd/config.toml --style ~/.config/swayosd/style.css &




# Reload Eww to apply new Pywal colors
eww -c ~/.config/eww/powermenu reload
eww -c ~/.config/eww/sidebar reload
eww -c ~/.config/eww/visualizer reload
