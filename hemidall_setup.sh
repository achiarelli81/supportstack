#!/bin/bash

# Define variables
HEIMDALL_CONFIG_PATH="/media/docker/hemidall/www/"
CONFIG_ZIP_URL="https://adamchiarelli.net/docker/hemidall_config.zip"
SUPPORT_TOOLS_PATH="/home/$USER/support-tools"
STOP_SWARM_SCRIPT="$SUPPORT_TOOLS_PATH/stop-support-tools.sh"
START_SWARM_SCRIPT="$SUPPORT_TOOLS_PATH/start-support-tools.sh"
OS_TYPE=""

# Function to select OS version
select_os_version() {
  echo "Please select your OS version:"
  echo "1) Fedora"
  echo "2) Ubuntu"
  echo "3) Linux Mint"
  echo "4) Pop!_OS"
  echo "5) RHEL-based (Red Hat, CentOS, AlmaLinux, etc.)"
  echo "6) Exit"

  read -p "Enter your choice (1-6): " os_choice

  case $os_choice in
    1)
      OS_TYPE="fedora"
      ;;
    2)
      OS_TYPE="ubuntu"
      ;;
    3)
      OS_TYPE="linuxmint"
      ;;
    4)
      OS_TYPE="popos"
      ;;
    5)
      OS_TYPE="rhel"
      ;;
    6)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      select_os_version
      ;;
  esac
}

# Function to install required dependencies
install_dependencies() {
  echo "Installing required dependencies..."
  case $OS_TYPE in
    fedora)
      sudo dnf install -y curl unzip
      ;;
    ubuntu|linuxmint|popos)
      sudo apt-get update && sudo apt-get install -y curl unzip
      ;;
    rhel)
      sudo yum install -y curl unzip
      ;;
    *)
      echo "Unsupported OS. Please install 'curl' and 'unzip' manually."
      exit 1
      ;;
  esac
  echo "Dependencies installed successfully."
}

# Prompt for OS selection
select_os_version

# Install dependencies
install_dependencies

# Get the host IP address
HOST_IP=$(hostname -I | awk '{print $1}')
if [ -z "$HOST_IP" ]; then
    echo "Error: Could not determine the host IP address."
    exit 1
fi
echo "Host IP Address: $HOST_IP"

# Change to the support-tools directory
echo "Navigating to $SUPPORT_TOOLS_PATH..."
if [ -d "$SUPPORT_TOOLS_PATH" ]; then
    cd "$SUPPORT_TOOLS_PATH" || { echo "Error: Failed to navigate to $SUPPORT_TOOLS_PATH"; exit 1; }
else
    echo "Error: Directory $SUPPORT_TOOLS_PATH does not exist."
    exit 1
fi

# Stop the Docker Swarm
echo "Stopping Docker Swarm..."
if [ -f "$STOP_SWARM_SCRIPT" ]; then
    bash "$STOP_SWARM_SCRIPT"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to stop the Docker Swarm."
        exit 1
    fi
else
    echo "Error: Stop Swarm script not found at $STOP_SWARM_SCRIPT."
    exit 1
fi

# Wait for 30 seconds before proceeding
echo -n "Waiting for 30 seconds before starting the swarm"
for i in {1..30}; do
  echo -n "."
  sleep 1
done
echo ""

# Create the required directories
echo "Creating Heimdall configuration directory..."
mkdir -p "$HEIMDALL_CONFIG_PATH"

# Download the heimdall_config.zip file
echo "Downloading heimdall_config.zip from $CONFIG_ZIP_URL..."
curl -o "/tmp/heimdall_config.zip" "$CONFIG_ZIP_URL"

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "heimdall_config.zip downloaded successfully."
else
    echo "Error: Failed to download heimdall_config.zip."
    exit 1
fi

# Unzip the configuration file to the Heimdall path
echo "Unzipping heimdall_config.zip to $HEIMDALL_CONFIG_PATH..."
unzip -o "/tmp/heimdall_config.zip" -d "$HEIMDALL_CONFIG_PATH"

if [ $? -eq 0 ]; then
    echo "Configuration unzipped successfully to $HEIMDALL_CONFIG_PATH."
else
    echo "Error: Failed to unzip heimdall_config.zip."
    exit 1
fi

# Update IPs in the unzipped configuration files
echo "Updating IP addresses in the configuration files to match the host IP..."
find "$HEIMDALL_CONFIG_PATH" -type f -exec sed -i "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/$HOST_IP/g" {} \;

if [ $? -eq 0 ]; then
    echo "IP addresses updated successfully to $HOST_IP."
else
    echo "Error: Failed to update IP addresses in the configuration files."
    exit 1
fi

# Start the Docker Swarm
echo "Starting Docker Swarm..."
if [ -f "$START_SWARM_SCRIPT" ]; then
    bash "$START_SWARM_SCRIPT"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to start the Docker Swarm."
        exit 1
    fi
else
    echo "Error: Start Swarm script not found at $START_SWARM_SCRIPT."
    exit 1
fi

# Cleanup
echo "Cleaning up temporary files..."
rm -f /tmp/heimdall_config.zip

echo "Setup complete. Access Heimdall at http://$HOST_IP/"
