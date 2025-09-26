#!/usr/bin/env bash

echo "--- debug_colors.sh started ---"

# --- Dependency Check ---
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it to continue."
    exit 1
fi

# --- Configuration ---
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$HOME/.config/quickshell/hyprdotsenv"

# --- Argument Check ---
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_image>"
    exit 1
fi
imgpath="$1"
if [ ! -f "$imgpath" ]; then
    echo "Error: Image file not found at '$imgpath'"
    exit 1
fi

# --- Color Generation ---
echo "Generating colors from image: $imgpath"
source "$VENV_DIR/bin/activate"
json_output=$(python3 "$SCRIPT_DIR/generate_colors_material.py" --path "$imgpath")
deactivate

if [ -z "$json_output" ]; then
    echo "Error: Color generation script produced no output."
    exit 1
fi
echo "--- Raw JSON Output ---"
echo "$json_output"
echo "-----------------------"

# --- File Creation ---
material_colors_path="$STATE_DIR/user/generated/material_colors.json"
term_colors_path="$STATE_DIR/user/generated/term_colors.json"

echo "Creating material colors file at: $material_colors_path"
echo "$json_output" | jq '.material_colors' > "$material_colors_path"

echo "Creating terminal colors file at: $term_colors_path"
echo "$json_output" | jq '.term_colors' > "$term_colors_path"

# --- Verification ---
echo "--- Verifying material_colors.json ---"
if [ -s "$material_colors_path" ]; then
    echo "File created successfully. Contents:"
    cat "$material_colors_path"
else
    echo "Error: material_colors.json is empty or was not created."
fi
echo "------------------------------------"

echo "--- Verifying term_colors.json ---"
if [ -s "$term_colors_path" ]; then
    echo "File created successfully. Contents:"
    cat "$term_colors_path"
else
    echo "Error: term_colors.json is empty or was not created."
fi
echo "----------------------------------"

echo "--- debug_colors.sh finished ---"
