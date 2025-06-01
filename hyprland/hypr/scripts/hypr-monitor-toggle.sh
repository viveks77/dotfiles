#!/bin/bash

# Define your monitor names
# VERIFY THESE NAMES with `hyprctl monitors all` when monitors are connected/disconnected.
# It's crucial they match exactly.
EXTERNAL="HDMI-A-1" # Your external monitor's Hyprland name
INTERNAL="eDP-1"    # Your internal laptop display's Hyprland name

# --- Important: The NVIDIA specific environment variables should ideally be set in hyprland.conf
# or in the script that launches Hyprland. If you also put them here, they'll be redundant but harmless.
# For a hotplug script triggered by udev/systemd, these are CRUCIAL to ensure the script interacts
# with Hyprland correctly and with the correct GPU context.
# export GBM_BACKEND=nvidia-drm
# export __GLX_VENDOR_LIBRARY_NAME=nvidia
# export LIBVA_DRIVER_NAME=nvidia
# export NVD_BACKEND=direct

echo "$(date): Running monitor toggle script" >> ~/.hypr/hotplug.log

# Determine if the external monitor is connected using hyprctl
# This is more reliable than `cat /sys/class/drm/...` for Hyprland's state.
if hyprctl monitors all | grep -q "${EXTERNAL}"; then
    echo "External monitor ($EXTERNAL) connected. Switching to external only."
    # Disable internal monitor
    hyprctl keyword monitor "$INTERNAL,disable"
    # Enable external monitor: preferred resolution, auto position, 1x scale
    # If you want a specific resolution and refresh rate, use:
    # hyprctl keyword monitor "$EXTERNAL,1920x1080@165,auto,1"
    # Make sure '1920x1080' and '165' are valid for your external monitor.
    hyprctl keyword monitor "$EXTERNAL,1920x1080@165.00Hz,auto,1"

    # Move all existing workspaces to the external monitor
    # This is important for a seamless "docked" experience
    for ws_id in $(hyprctl workspaces | grep -E '^workspace ID' | awk '{print $3}'); do
        hyprctl dispatch moveworkspacetomonitor "$ws_id" "$EXTERNAL"
    done

else
    echo "External monitor ($EXTERNAL) disconnected. Switching to internal only."
    # Disable external monitor
    hyprctl keyword monitor "$EXTERNAL,disable"
    # Enable internal laptop display: preferred resolution, auto position, 1x scale
    # hyprctl keyword monitor "$INTERNAL,1920x1080@60,auto,1" # Example for specific res/rate
    hyprctl keyword monitor "$INTERNAL,preferred,auto,1"

    # Move all existing workspaces back to the internal monitor
    for ws_id in $(hyprctl workspaces | grep -E '^workspace ID' | awk '{print $3}'); do
        hyprctl dispatch moveworkspacetomonitor "$ws_id" "$INTERNAL"
    done
fi

# Reloading Hyprland config might be needed to apply changes sometimes,
# but `monitor` rules often apply immediately.
# hyprctl reload