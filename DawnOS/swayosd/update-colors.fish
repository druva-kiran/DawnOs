#!/usr/bin/env fish
# Update swayosd colors from pywal cache

set COLORS_JSON "$HOME/.cache/wal/colors.json"

if not test -f "$COLORS_JSON"
    echo "Pywal colors not found at $COLORS_JSON"
    exit 1
end

# Parse pywal colors
set BG (jq -r '.colors.color0' "$COLORS_JSON")
set ACCENT (jq -r '.colors.color4' "$COLORS_JSON")
set FG (jq -r '.colors.color7' "$COLORS_JSON")
set FG_BRIGHT (jq -r '.colors.color15' "$COLORS_JSON")

# Convert hex to rgba with alpha
function hex_to_rgba
    set hex "$argv[1]"
    set alpha "$argv[2]"
    # Remove # if present
    set hex (string replace -r '^#' '' "$hex")
    # Convert hex to RGB using string slicing
    set r (printf '%d' "0x"(string sub -l 2 "$hex"))
    set g (printf '%d' "0x"(string sub -s 3 -l 2 "$hex"))
    set b (printf '%d' "0x"(string sub -s 5 -l 2 "$hex"))
    echo "rgba($r, $g, $b, $alpha)"
end

# Generate CSS content
set BG_RGBA (hex_to_rgba "$BG" "0.75")

# Write CSS using echo and redirection (compatible with fish)
echo "window#osd {
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: $BG_RGBA;
  padding: 2px 6px;
  min-width: 100px;
  max-width: 280px;
  opacity: 0.88;
  font-size: 0.75rem;
}

window#osd #container {
  margin: 0;
}

window#osd image,
window#osd label {
  color: $FG_BRIGHT;
  font-weight: 500;
  letter-spacing: 0.01em;
}

window#osd progressbar:disabled,
window#osd image:disabled {
  opacity: 0.4;
}

window#osd progressbar,
window#osd segmentedprogress {
  min-height: 6px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.08);
  border: none;
}

window#osd trough,
window#osd segment {
  min-height: inherit;
  border-radius: inherit;
  border: none;
  background: rgba(255, 255, 255, 0.15);
}

window#osd progress,
window#osd segment.active {
  min-height: inherit;
  border-radius: inherit;
  border: none;
  background: $ACCENT;
}

window#osd segment {
  margin-left: 3px;
}

window#osd segment:first-child {
  margin-left: 0;
}" > ~/.config/swayosd/style.css

echo "✓ swayosd colors updated from pywal"
