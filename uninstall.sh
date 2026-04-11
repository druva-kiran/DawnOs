#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAWNOS_DIR="$REPO_DIR/DawnOS"
BACKUP_DIR="$HOME/.dotfiles_backup"
APPLICATIONS_DIR="$HOME/.local/share/applications"

info() {
  printf '\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m!!\033[0m %s\n' "$*"
}

remove_link() {
  local source="$1"
  local target="$2"

  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$source" ]; then
    rm "$target"
    info "Removed symlink: $target"
  else
    warn "Skipping $target; not a symlink to this repo."
  fi
}

restore_backup() {
  local target="$1"
  local name="$(basename "$target")"
  if [ ! -d "$BACKUP_DIR" ]; then
    return
  fi

  local backup_path
  backup_path="$(find "$BACKUP_DIR" -type f -name "$name" -o -type d -name "$name" | sort | tail -n1)"
  if [ -n "$backup_path" ]; then
    mkdir -p "$(dirname "$target")"
    mv "$backup_path" "$target"
    info "Restored backup for $target from $backup_path"
  fi
}

remove_config_links() {
  local mappings=(
    "hypr:$HOME/.config/hypr"
    "eww:$HOME/.config/eww"
    "waybar:$HOME/.config/waybar"
    "kitty:$HOME/.config/kitty"
    "rofi:$HOME/.config/rofi"
    "fish:$HOME/.config/fish"
    "swayosd:$HOME/.config/swayosd"
    "fastfetch:$HOME/.config/fastfetch"
    "matugen:$HOME/.config/matugen"
    "nvim:$HOME/.config/nvim"
    "swaync:$HOME/.config/swaync"
    "sources:$HOME/.config/sources"
    "Kvantum:$HOME/.config/Kvantum"
  )

  for item in "${mappings[@]}"; do
    local source_dir="${item%%:*}"
    local target_dir="${item#*:}"
    if [ -d "$DAWNOS_DIR/$source_dir" ]; then
      remove_link "$DAWNOS_DIR/$source_dir" "$target_dir"
      restore_backup "$target_dir"
    fi
  done

  remove_link "$DAWNOS_DIR/gtk/gtk-3.0" "$HOME/.config/gtk-3.0"
  restore_backup "$HOME/.config/gtk-3.0"
  remove_link "$DAWNOS_DIR/gtk/gtk-4.0" "$HOME/.config/gtk-4.0"
  restore_backup "$HOME/.config/gtk-4.0"
  remove_link "$DAWNOS_DIR/qt/qt5ct" "$HOME/.config/qt5ct"
  restore_backup "$HOME/.config/qt5ct"
  remove_link "$DAWNOS_DIR/qt/qt6ct" "$HOME/.config/qt6ct"
  restore_backup "$HOME/.config/qt6ct"
}

remove_wallpaper_link() {
  local target="$HOME/Wallpapers"
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$DAWNOS_DIR/assets/wallpapers" ]; then
    rm "$target"
    info "Removed wallpaper symlink: $target"
  fi
}

remove_pixie_sddm() {
  local theme_dir="/usr/share/sddm/themes/pixie"
  local config_dir="/etc/sddm.conf.d"

  if [ -d "$theme_dir" ]; then
    sudo rm -rf "$theme_dir"
    info "Removed Pixie SDDM theme from $theme_dir"
  fi

  if [ -f "$config_dir/theme.conf" ]; then
    sudo rm -f "$config_dir/theme.conf"
    info "Removed Pixie SDDM config from $config_dir/theme.conf"
  fi
}

remove_desktop_links() {
  if [ -d "$DAWNOS_DIR/assets/webapps" ]; then
    while IFS= read -r -d '' desktop; do
      local target="$APPLICATIONS_DIR/$(basename "$desktop")"
      if [ -f "$target" ]; then
        rm "$target"
        info "Removed webapp: $target"
      fi
    done < <(find "$DAWNOS_DIR/assets/webapps" -maxdepth 1 -name '*.desktop' -print0)
  fi
}

main() {
  info "Uninstalling dotfiles symlinks created by this repository"
  remove_config_links
  remove_wallpaper_link
  remove_desktop_links
  remove_pixie_sddm
  info "Uninstall complete. Backups remain in $BACKUP_DIR"
}

main "$@"
