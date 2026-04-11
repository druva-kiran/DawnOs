#!/usr/bin/env bash
set -euo pipefail

# --- 1. SAFETY CHECK ---
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: Do not run this script with sudo."
   echo "Run it as: ./install.sh"
   exit 1
fi

# --- 2. AUTOMATIC PATH DETECTION ---
# This looks for your 'hypr' folder even if it is inside DawnOs/DawnOs/
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# First try: find hypr folder and get its parent
DAWNOS_DIR=$(find "$REPO_DIR" -maxdepth 3 -type d -name "hypr" -printf '%h\n' 2>/dev/null | head -n 1)

# Fallback: check common locations
if [ -z "$DAWNOS_DIR" ] || [ ! -d "$DAWNOS_DIR/hypr" ]; then
    if [ -d "$REPO_DIR/DawnOS/hypr" ]; then
        DAWNOS_DIR="$REPO_DIR/DawnOS"
    elif [ -d "$REPO_DIR/hypr" ]; then
        DAWNOS_DIR="$REPO_DIR"
    fi
fi

if [ -z "$DAWNOS_DIR" ] || [ ! -d "$DAWNOS_DIR/hypr" ]; then
    echo "ERROR: Could not find your configuration folders (like 'hypr')."
    echo "Make sure you are running this from your DawnOs folder."
    exit 1
fi

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

# --- 3. PACKAGE LISTS ---
# Official Arch packages - all dependencies for DawnOS
pacman_pkgs=(
    # Base & Shell
    git fish base-devel neovim starship fastfetch

    # File Management
    nautilus gvfs gvfs-smb udisks2 eza

    # Hyprland & Wayland
    hyprland waybar hyprlock hypridle hyprshot hyprsunset hyprcursor

    # Screenshot & Image
    satty grim slurp imagemagick

    # Audio (PipeWire + WirePlumber + Tools)
    pipewire pipewire-pulse pipewire-alsa wireplumber
    pulseaudio-utils playerctl

    # Brightness & OSD
    brightnessctl swayosd wob

    # Network & Bluetooth
    networkmanager network-manager-applet
    bluez bluez-utils

    # Clipboard
    wl-clipboard cliphist wl-clip-persist

    # Qt & GTK Theming
    qt5ct qt6ct qt5-wayland qt6-wayland
    gtk3 gtk4 libadwaita
    papirus-icon-theme breeze breeze-icons

    # Kvantum for Qt theming
    kvantum

    # Fonts
    ttf-jetbrains-mono-nerd ttf-iosevka

    # Apps
    p7zip vlc gnome-calculator gnome-clocks

    # XDG Portals
    xdg-desktop-portal xdg-desktop-portal-gtk

    # Misc
    polkit-kde-agent libnotify

    # Webapps support
    wmctrl xdg-utils
)

# AUR packages
aur_pkgs=(
    # Themes & Icons
    adw-gtk3 adw-gtk-theme darkly-bin google-sans-flex bibata-cursor-theme

    # EWW & Visuals
    eww-wayland swww cava

    # File & System
    yazi-bin matugen-bin btop

    # Network Tools (TUI)
    bluetui impala wiremix-git awww

    # Browser
    google-chrome-stable

    # Fonts
    ttf-iosevka
)

# --- 4. INSTALLATION ---
install_packages() {
    info "Installing official Arch packages..."
    sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"

    if ! command -v yay >/dev/null 2>&1; then
        info "Installing yay..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm && cd -
    fi

    info "Installing AUR packages..."
    yay -S --needed --noconfirm "${aur_pkgs[@]}"

    # --- NVIDIA DETECTION ---
    info "Checking for NVIDIA hardware..."
    if lspci | grep -qi "nvidia"; then
        info "NVIDIA GPU detected! Installing NVIDIA drivers..."
        # Install nvidia-dkms for most compatibility (works with most kernels)
        yay -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings
        info "NVIDIA drivers installed. You may need to reboot."
    fi
}

# --- 5. COPY (PASTE) CONFIGS ---
copy_configs() {
    info "Pasting configurations from $DAWNOS_DIR to ~/.config..."
    mkdir -p "$HOME/.config"

    # Folders detected in your folder structure
    local folders=(
        "hypr" "eww" "waybar" "kitty" "rofi" "fish" "fastfetch" "matugen"
        "nvim" "swaync" "swayosd" "Kvantum" "scripts" "gtk"
    )

    for folder in "${folders[@]}"; do
        if [ -d "$DAWNOS_DIR/$folder" ]; then
            rm -rf "$HOME/.config/$folder"
            cp -rf "$DAWNOS_DIR/$folder" "$HOME/.config/"
            info "Pasted $folder"
        else
            warn "Source $folder not found in $DAWNOS_DIR"
        fi
    done

    # --- HANDLE SOURCES FOLDER ---
    # Hyprland sources config files from ~/.config/sources/
    if [ -d "$DAWNOS_DIR/sources" ] && [ "$(ls -A "$DAWNOS_DIR/sources" 2>/dev/null)" ]; then
        rm -rf "$HOME/.config/sources"
        cp -rf "$DAWNOS_DIR/sources" "$HOME/.config/"
        info "Pasted sources (hyprland config files)"
    else
        warn "sources folder not found"
    fi

    # --- HANDLE WEBAPPS FOLDER ---
    # Webapps are in assets/webapps/
    if [ -d "$DAWNOS_DIR/assets/webapps" ] && [ "$(ls "$DAWNOS_DIR/assets/webapps/"*.desktop 2>/dev/null)" ]; then
        mkdir -p "$HOME/.local/share/applications"
        cp -rf "$DAWNOS_DIR/assets/webapps/"*.desktop "$HOME/.local/share/applications/"
        info "Installed webapp shortcuts to ~/.local/share/applications/"
    else
        warn "assets/webapps folder not found or no .desktop files present"
    fi

    # Handle Nested folders (GTK and QT)
    local subfolders=("gtk/gtk-3.0" "gtk/gtk-4.0" "qt/qt5ct" "qt/qt6ct")
    for sub in "${subfolders[@]}"; do
        if [ -d "$DAWNOS_DIR/$sub" ]; then
            local target_name=$(basename "$sub")
            rm -rf "$HOME/.config/$target_name"
            cp -rf "$DAWNOS_DIR/$sub" "$HOME/.config/$target_name"
            info "Pasted $target_name"
        fi
    done
    
    # --- WALLPAPER LOGIC ---
    info "Setting up Wallpapers..."
    mkdir -p "$HOME/Wallpapers"
    if [ -d "$DAWNOS_DIR/assets" ] && [ "$(ls -A "$DAWNOS_DIR/assets" 2>/dev/null)" ]; then
        cp -rf "$DAWNOS_DIR/assets/"* "$HOME/Wallpapers/"
        info "Wallpapers pasted to $HOME/Wallpapers"
    else
        warn "No wallpapers found in $DAWNOS_DIR/assets"
    fi

    # --- PIXIE SDDM THEME INSTALLATION ---
    info "Installing Pixie SDDM theme..."
    if [ -d "$DAWNOS_DIR/sddm" ]; then
        # Check if SDDM is installed
        if command -v sddm-greeter-qt6 >/dev/null 2>&1 || command -v sddm-greeter >/dev/null 2>&1; then
            THEME_DIR="/usr/share/sddm/themes/pixie"

            # Detect Qt version for logging
            if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
                info "Detected Qt6 (Modern) SDDM"
            else
                info "Detected Qt5 (Legacy) SDDM"
            fi

            # Install the theme
            sudo mkdir -p "$THEME_DIR"
            sudo cp -r "$DAWNOS_DIR/sddm/"* "$THEME_DIR/"
            sudo chmod -R 755 "$THEME_DIR"

            # Create SDDM config
            sudo mkdir -p /etc/sddm.conf.d
            echo -e "[Theme]\nCurrent=pixie" | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
            info "Pixie SDDM theme installed and set as default"
        else
            warn "SDDM not detected. Skipping  SDDM theme installation."
            info "To install manually later: cd $DAWNOS_DIR/sddm && sudo ./install.sh"
        fi
    else
        warn "sddm folder not found"
    fi
}

# --- 6. FINALIZE (SHELL, SERVICES & USERNAMES) ---
finalize() {
    info "Fixing username in eww SCSS files..."
    if [ -d "$HOME/.config/eww" ]; then
        find "$HOME/.config/eww" -type f -name "*.scss" -exec sed -i "s|%USERNAME%|$USER|g" {} +
    fi

    info "Setting fish as default shell..."
    local fish_path=$(command -v fish)
    if [ -n "$fish_path" ]; then
        if ! grep -qxF "$fish_path" /etc/shells; then
            echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
        fi
        sudo chsh -s "$fish_path" "$USER"
    fi

    # Fix ownership of .config folder only (not entire home directory)
    sudo chown -R $USER:$USER "$HOME/.config"

    # --- ENABLE ESSENTIAL SERVICES ---
    info "Enabling system services..."

    # NetworkManager
    if command -v nmcli >/dev/null 2>&1; then
        sudo systemctl enable NetworkManager
        info "NetworkManager enabled"
    fi

    # Bluetooth
    if [ -f /usr/lib/systemd/system/bluetooth.service ]; then
        sudo systemctl enable bluetooth
        info "Bluetooth service enabled"
    fi

    # PipeWire Audio
    if [ -f /usr/lib/systemd/system/pipewire.service ]; then
        systemctl --user enable pipewire pipewire-pulse wireplumber 2>/dev/null || true
        info "PipeWire audio services enabled"
    fi

    # Set default cursor theme system-wide
    info "Setting up cursor theme..."
    if [ -d /usr/share/icons/Bibata-Modern-Classic ]; then
        sudo mkdir -p /etc/X11/cursor-theme
        cat <<EOF | sudo tee /etc/X11/cursor-theme/index.theme
[Icon Theme]
Inherits=Bibata-Modern-Classic
EOF
    fi
}

# --- MAIN EXECUTION ---
main() {
    install_packages
    copy_configs
    finalize

    info "DawnOS Installation Complete!"
    echo "-------------------------------------------------------"
    echo ""
    echo "  What was installed:"
    echo "  - Hyprland with all dependencies"
    echo "  - EWW widgets with audio visualizer (cava)"
    echo "  - Waybar with custom modules"
    echo "  - SwayNC notifications"
    echo "  - Matugen theming system"
    echo "  - Fish shell with starship prompt"
    echo "  - NetworkManager & Bluetooth enabled"
    echo "  - PipeWire audio system"
    echo "  - Webapp shortcuts (Discord, GitHub, Gmail, etc.)"
    echo "  - Pixie SDDM theme (login screen)"
    echo "  - Hyprland config sources (animations, keybindings, etc.)"
    echo ""
    echo "  First boot checklist:"
    echo "  1. Enable NetworkManager: sudo systemctl enable NetworkManager"
    echo "  2. Enable Bluetooth: sudo systemctl enable bluetooth"
    echo "  3. Add user to required groups (if needed)"
    echo "  4. Run: systemctl --user enable pipewire pipewire-pulse wireplumber"
    echo ""
    echo "-------------------------------------------------------"
    read -p "==> Reboot now to start DawnOS? [y/N]: " reboot_choice

    if [[ "$reboot_choice" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        info "Rebooting system..."
        sudo reboot
    else
        info "Reboot skipped. Please reboot manually to apply all changes."
    fi
}

main "$@"