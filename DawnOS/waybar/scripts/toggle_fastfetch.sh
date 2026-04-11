#!/bin/bash
if hyprctl clients | grep -q 'class: floating_fastfetch'; then
    hyprctl dispatch closewindow class:floating_fastfetch
else
    kitty --class floating_fastfetch --hold -e fastfetch &
fi
