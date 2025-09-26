#!/bin/sh

# Wallpaper directory
WALL_DIR="${HOME}/walls"

# Get a random wallpaper from the directory
get_random_wallpaper() {
    find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1
}

# Set wallpaper using swww
set_wallpaper_hyprland() {
    BG="$(get_random_wallpaper)"
    TRANS_TYPE="center"

    # Start swww if not running
    if ! pgrep -x swww-daemon >/dev/null; then
        swww-daemon &
        sleep 1
    fi

    # Set wallpaper
    swww img "$BG" --transition-fps 165 --transition-type "$TRANS_TYPE" --transition-duration 1

    # Generate color scheme using matugen (but don't apply wallpaper)
    if command -v matugen >/dev/null 2>&1; then
        matugen image "$BG"
    fi
}

set_wallpaper_hyprland
