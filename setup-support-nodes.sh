#!/bin/bash
# Usage: ./setup-support-nodes.sh

# Constants for colors
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

# Print the header
echo
echo -e "${YELLOW}##########################################################################"
echo -e "   Setting up nodes"
echo -e "##########################################################################${NO_COLOR}"
echo

# Function to prompt for operating system
select_os_version() {
  echo "Please select your operating system:"
  echo "1) Fedora"
  echo "2) Ubuntu"
  echo "3) Linux Mint"
  echo "4) Pop!_OS"
  echo "5) RHEL-based (Red Hat, CentOS, AlmaLinux, etc.)"
  echo "6) Exit"

  # Read user input
  read -p "Enter your choice (1-6): " os_choice

  # Process user choice
  case $os_choice in
    1)
      os_version="fedora"
      echo "You have selected Fedora."
      ;;
    2)
      os_version="ubuntu"
      echo "You have selected Ubuntu."
      ;;
    3)
      os_version="linuxmint"
      echo "You have selected Linux Mint."
      ;;
    4)
      os_version="popos"
      echo "You have selected Pop!_OS."
      ;;
    5)
      os_version="rhel"
      echo "You have selected RHEL-based OS (Red Hat, CentOS, AlmaLinux, etc.)."
      ;;
    6)
      echo "Exiting... Goodbye!"
      exit 0
      ;;
    *)
      echo "Invalid choice. Please enter a number between 1 and 6."
      select_os_version
      ;;
  esac
}

# Main script
select_os_version

# Create directories
dirs=(
  /media/docker
  /media/docker/firefox
  /media/docker/wireshark
  /media/docker/wireshark/downloads
  /media/docker/netdata
  /media/docker/netdata/netdatalib
  /media/docker/netdata/netdatacache
  /media/docker/netdata/netdataconfig
  /media/docker/ubuntu_desktop
  /media/docker/ohif-orthanc
  /media/docker/mirth
  /media/docker/postgres/pgsql_volume
  /media/docker/hemidall/www/
)

echo "Creating required directories..."
for dir in "${dirs[@]}"; do
  sudo mkdir -p "$dir"
done
echo "Directories created successfully."

# Set permissions
echo "Setting permissions for directories..."
sudo chown -R $USER:root /media/docker
sudo chmod 755 /media/docker
sudo chmod 777 /media/docker/mirth
echo "Permissions set successfully."

# Run Wireshark Docker container
echo "Running Wireshark Docker container..."
sudo docker run -d \
  --name=wireshark \
  --net=host \
  --cap-add=NET_ADMIN \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -p 3001:3001 \
  -v /media/docker/wireshark:/config \
  -v /media/docker/wireshark/downloads:/downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/wireshark:latest

# Check if Wireshark container started successfully
if [ $? -eq 0 ]; then
  echo "Wireshark container started successfully."
else
  echo "Failed to start Wireshark container. Please check Docker logs."
  exit 1
fi

# Stop Wireshark container
echo "Stopping Wireshark Docker container..."
sudo docker stop wireshark
if [ $? -eq 0 ]; then
  echo "Wireshark container stopped successfully."
else
  echo "Failed to stop Wireshark container. Please check Docker logs."
  exit 1
fi

echo
echo -e "${YELLOW}##########################################################################"
echo -e "   Node setup complete. Please verify the setup and start the containers as needed."
echo -e "##########################################################################${NO_COLOR}"
