#!/bin/bash

# Function to navigate directories
navigate_dirs() {
    local current_dir="$PWD"
    while true; do
        echo "Current directory: $current_dir"
        echo "Select a subdirectory or press ENTER to choose this directory:"
        select dir in ../ $(ls -d */ 2>/dev/null) "Choose this"; do
            if [[ $dir == "Choose this" ]]; then
                export root=$current_dir
                return
            elif [[ -d "$current_dir/$dir" ]]; then
                cd "$current_dir/$dir" || continue
                current_dir="$PWD"
                break
            else
                echo "Invalid selection, try again."
            fi
        done
    done
}

# Save original directory
original_pwd="$PWD"

# Let user navigate to the root directory
echo "Navigate to the root folder containing the DICOM files."
navigate_dirs

# Return to the original directory
cd "$original_pwd"