#!/bin/sh
# USAGE: sudo ./curie_prep.sh

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
            PACKAGE_MANAGER="sudo dnf"
            PACKAGE_LIST="curl docker-compose inxi nfs-utils openldap-clients scsi-target-utils iftop nmap ncdu iotop java-11-openjdk-devel dcmtk ethtool"
            ;;
        2)
            os_version="ubuntu"
            PACKAGE_MANAGER="sudo apt-get"
            PACKAGE_LIST="curl docker-compose inxi nfs-common ldap-utils scsitools iftop nmap ncdu iotop default-jdk dcmtk ethtool"
            ;;
        3)
            os_version="linuxmint"
            PACKAGE_MANAGER="sudo apt-get"
            PACKAGE_LIST="curl docker-compose inxi nfs-common ldap-utils scsitools iftop nmap ncdu iotop default-jdk dcmtk ethtool"
            ;;
        4)
            os_version="popos"
            PACKAGE_MANAGER="sudo apt-get"
            PACKAGE_LIST="curl docker-compose inxi nfs-common ldap-utils scsitools iftop nmap ncdu iotop default-jdk dcmtk ethtool"
            ;;
        5)
            os_version="rhel"
            PACKAGE_MANAGER="sudo yum"
            PACKAGE_LIST="curl docker-compose inxi nfs-utils openldap-clients scsi-target-utils iftop nmap ncdu iotop java-11-openjdk-devel dcmtk ethtool"
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

# Function to install packages
install_packages() {
    echo "Updating system and installing required packages for $os_version..."
    $PACKAGE_MANAGER update -y
    $PACKAGE_MANAGER upgrade -y
    $PACKAGE_MANAGER install -y $PACKAGE_LIST
    echo "Downloading Docker installation script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    echo "Packages installed successfully for $os_version."
}

# Main script
echo
echo -e $YELLOW"##########################################################################"
echo -e "   Curie Server Prep Version: 1.1"
echo -e "##########################################################################"$NO_COLOR
echo
echo "This script will install all needed software to prepare a Curie server."
sleep 5

# Select OS and install packages
select_os_version

echo "Updating system and installing prerequisites. This may take a while."
sleep 5

install_packages

sleep 15

# Prompt to reboot
read -p "Do you want to reboot? (yes/no) " yn
case $yn in
    yes)
        echo "Good choice, it's time for a coffee anyway."
        echo "Rebooting now, time for golf."
        sleep 5
        sudo reboot
        ;;
    no)
        echo "You really should consider rebooting, it does a system good..."
        exit
        ;;
    *)
        echo "Invalid response."
        exit 1
        ;;
esac
