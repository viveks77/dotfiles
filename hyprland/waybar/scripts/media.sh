#!/bin/bash

# Equalizer frames (cycle of bar shapes)
frames=(
  "▁ ▂ ▃ ▂"
  "▂ ▃ ▂ ▅"
  "▃ ▂ ▅ ▃"
  "▄ ▅ ▃ ▆"
  "▅ ▃ ▆ ▇"
  "▆ ▇ ▅ █"
  "▇ █ ▇ ▆"
  "█ ▇ ▆ ▅"
)

frame_index=$(( $(date +%s) % ${#frames[@]} ))
eq="${frames[$frame_index]}"

# Media title
info=$(playerctl metadata --format '{{title}} - {{artist}}' 2>/dev/null)

if [[ -z "$info" ]]; then
  echo ""
else
  echo "$eq  $info"
fi

