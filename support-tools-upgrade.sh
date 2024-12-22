#!/bin/sh

# Colors for output
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

# Function to select OS version
select_os_version() {
    echo "Please select your operating system:"
    echo "1) Fedora"
    echo "2) Ubuntu"
    echo "3) Linux Mint"
    echo "4) Pop!_OS"
    echo "5) RHEL-based (Red Hat, CentOS, AlmaLinux, etc.)"
    echo "6) Exit"

    read -p "Enter your choice (1-6): " os_choice

    case $os_choice in
        1)
            os_version="fedora"
            BASE_URL="https://adamchiarelli.net/docker/fedora"
            echo "You have selected Fedora."
            ;;
        2)
            os_version="ubuntu"
            BASE_URL="https://adamchiarelli.net/docker/ubuntu"
            echo "You have selected Ubuntu."
            ;;
        3)
            os_version="linuxmint"
            BASE_URL="https://adamchiarelli.net/docker/linuxmint"
            echo "You have selected Linux Mint."
            ;;
        4)
            os_version="popos"
            BASE_URL="https://adamchiarelli.net/docker/popos"
            echo "You have selected Pop!_OS."
            ;;
        5)
            os_version="rhel"
            BASE_URL="https://adamchiarelli.net/docker/redhat"
            echo "You have selected a RHEL-based OS (Red Hat, CentOS, AlmaLinux, etc.)."
            ;;
        6)
            echo "Exiting... Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            select_os_version
            ;;
    esac
}

# Main script
echo
echo -e $YELLOW"##########################################################################"
echo -e "   Upgrading to: Support Tools version 1.2"
echo -e "                 Adding netdata container"
echo -e "                 Cleaning up old unused containers"
echo -e "##########################################################################"$NO_COLOR
echo

# Select OS and set the base URL
select_os_version

# Upgrade current installation
echo "Upgrading current installation..."
cd /home/$USER/support-tools || { echo "Support-tools directory not found! Exiting..."; exit 1; }

echo "Stopping current support tools stack..."
sudo ./stop-support-tools.sh
if [ $? -ne 0 ]; then
    echo "Failed to stop the support tools stack. Exiting..."
    exit 1
fi

echo "Cleaning up old files and containers..."
sleep 10
cd ..
sudo rm -rf /media/docker/viewer-dist /media/docker/portainer /media/docker/shared /media/docker/hemidall /home/$USER/support-tools /media/docker/glances /home/$USER/support-tools-setup.sh
sudo docker system prune -f
sleep 15

# Update stack
echo "Updating stack to the newest version..."
cd /home/$USER/STI || { echo "STI directory not found! Exiting..."; exit 1; }
./support-tools-setup.sh
if [ $? -ne 0 ]; then
    echo "Failed to update the stack. Exiting..."
    exit 1
fi

# Upgrade Wireshark
echo "Upgrading Wireshark container..."
sudo docker stop wireshark
sudo docker rm wireshark
if [ $? -ne 0 ]; then
    echo "Failed to remove Wireshark container. Proceeding anyway..."
fi

# Start support stack
echo "Starting support stack..."
cd ~/STI || { echo "STI directory not found! Exiting..."; exit 1; }
./setup-support-nodes.sh
if [ $? -ne 0 ]; then
    echo "Failed to run setup-support-nodes.sh. Exiting..."
    exit 1
fi

cd ~/support-tools || { echo "Support-tools directory not found! Exiting..."; exit 1; }
sudo ./start-support-tools.sh
if [ $? -ne 0 ]; then
    echo "Failed to start the support tools stack. Exiting..."
    exit 1
fi

# Completion message
sleep 3
echo -e "${YELLOW}All done, time for golf!${NO_COLOR}"
sleep 2
exit
