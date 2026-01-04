#!/usr/bin/env bash

echo "Running autostart script..."
sleep 3
echo "Changing wallpaper"
python3 ~/.config/ignacio-utilities/bingbg.py
echo "Starting 1Password..."
1password
echo "Autostart script completed."
