#!/bin/bash
#
# save-installed-extensions.sh
#
# Description:
# This script retrieves the list of installed extensions from Visual Studio Code
# and Cursor, and saves them into their respective configuration directories
# within this project.
#
# Assumes the following directory structure:
# .
# ├── cursor/
# └── vscode/
#
# The output files will be:
# - vscode/installed-extensions.txt
# - cursor/installed-extensions.txt

# --- Configuration ---

# Set the script to exit immediately if a command exits with a non-zero status.
set -e

# --- Main Logic ---

echo "Starting to fetch installed extensions..."

# Get the absolute path of the directory containing this script.
# This ensures that the script can be run from any location.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Navigate to the project's root directory (one level up from `shell-scripts`).
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# Define paths for the output files.
VSCODE_OUTPUT_FILE="${PROJECT_ROOT}/vscode/installed-extensions.txt"
CURSOR_OUTPUT_FILE="${PROJECT_ROOT}/cursor/installed-extensions.txt"

# --- Visual Studio Code ---

# Check if the 'code' command-line tool is available in the system's PATH.
if command -v code &> /dev/null; then
    echo "Found 'code' command. Fetching VS Code extensions..."
    # Execute the command to list extensions and redirect the output to the specified file.
    # The `|| true` part ensures that the script doesn't exit if the command fails for some reason.
    code --list-extensions > "$VSCODE_OUTPUT_FILE" || true
    echo "Successfully saved VS Code extensions to: ${VSCODE_OUTPUT_FILE}"
else
    # If 'code' is not found, print a warning message.
    echo "Warning: 'code' command not found. Skipping VS Code extensions."
    echo "Please make sure 'code' is in your system's PATH."
fi

echo # Add a blank line for readability.

# --- Cursor ---

# Check if the 'cursor' command-line tool is available in the system's PATH.
if command -v cursor &> /dev/null; then
    echo "Found 'cursor' command. Fetching Cursor extensions..."
    # Execute the command to list extensions and save them to the file.
    cursor --list-extensions > "$CURSOR_OUTPUT_FILE" || true
    echo "Successfully saved Cursor extensions to: ${CURSOR_OUTPUT_FILE}"
else
    # If 'cursor' is not found, print a warning message.
    echo "Warning: 'cursor' command not found. Skipping Cursor extensions."
    echo "If you have Cursor installed, ensure its command-line tool is in your system's PATH."
    echo "Example for macOS: sudo ln -s /Applications/Cursor.app/Contents/Resources/app/bin/cursor /usr/local/bin/cursor"
fi

echo # Add a blank line for readability.

echo "Script finished."

