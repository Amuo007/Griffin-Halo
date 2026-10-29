#!/bin/bash
# Re-register global classes after script edits
godot --headless --editor --quit > /tmp/refresh.txt 2>&1
