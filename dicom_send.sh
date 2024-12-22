#!/bin/bash

# Hardcoded path to the dcm4che bin directory
bin_path="/home/enlitic/dcm4che/dcm4che-5.24.1/bin"

# Path to save the last command
last_command_file="$HOME/.last_storescu_command"

# Check if the storescu executable exists
if [[ ! -f "$bin_path/storescu" ]]; then
    echo "Error: The 'storescu' executable does not exist in the folder '$bin_path'."
    echo "Contents of the folder:"
    ls -l "$bin_path"
    exit 1
fi

# Check if storescu is executable
if [[ ! -x "$bin_path/storescu" ]]; then
    echo "Error: The 'storescu' file is not executable. Trying to fix..."
    chmod +x "$bin_path/storescu"
    if [[ $? -ne 0 ]]; then
        echo "Failed to make 'storescu' executable. Check permissions or ownership."
        exit 1
    fi
    echo "'storescu' is now executable."
fi

# Load the last command if it exists
if [[ -f "$last_command_file" ]]; then
    last_command=$(cat "$last_command_file" | tr -d '"') # Remove any extra quotes
    echo "Last command: $last_command"
    read -p "Do you want to reuse the last command with a new AE Title? (y/n): " reuse_last

    if [[ "$reuse_last" =~ ^[Yy]$ ]]; then
        # Extract the current AE Title from the last command
        current_aetitle=$(echo "$last_command" | grep -oP '(?<=-c )[^@]+')
        echo "Current AE Title: $current_aetitle"
        read -p "Enter a new AE Title (or press Enter to keep '$current_aetitle'): " aetitle
        aetitle=${aetitle:-$current_aetitle}

        # Replace the AE Title in the command
        command=$(echo "$last_command" | sed "s/-c $current_aetitle@/-c $aetitle@/")
    fi
fi

# If no command was reused, construct a new one
if [[ -z "$command" ]]; then
    read -p "Enter the AE Title: " aetitle
    read -p "Enter the IP Address: " ipaddress
    read -p "Enter the Port: " port
    read -p "Enter additional arguments for the storescu command (or press Enter to skip): " additional_args

    # Construct the command
    command="sudo \"$bin_path/storescu\" -c \"$aetitle@$ipaddress:$port\" $additional_args"
fi

# Show the final command and allow editing
echo "The following command will be executed:"
echo "$command"
read -p "Do you want to edit the command before running it? (y/n): " edit_command

if [[ "$edit_command" =~ ^[Yy]$ ]]; then
    # Open the command in an editor for user to edit
    temp_file=$(mktemp)
    echo "$command" > "$temp_file"
    ${EDITOR:-nano} "$temp_file"
    command=$(cat "$temp_file")
    rm "$temp_file"
fi

# Confirm before execution
read -p "Are you sure you want to execute this command? (y/n): " confirm_execution
if [[ ! "$confirm_execution" =~ ^[Yy]$ ]]; then
    echo "Command execution cancelled."
    exit 0
fi

# Execute the final command
eval "$command"

# Save the command for future use
echo "$command" > "$last_command_file"
echo "Command saved for future runs."
