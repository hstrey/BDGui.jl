#!/bin/bash

# Prompt user for a directory path
read -p "Enter a directory path: " user_path

# Extract the parent directory
parent_dir=$(dirname "$user_path")

# Check if the parent directory exists
if [ -d "$parent_dir" ]; then
    # Check if the target directory exists
    if [ ! -d "$user_path" ]; then
        mkdir "$user_path"
        echo "Created directory: $user_path"
    else
        echo "Directory already exists: $user_path"
    fi

    # Export the path
    export output_dir="$user_path"
    #echo "Exported output_dir=$output_dir"
else
    echo "Parent directory does not exist: $parent_dir"
fi
