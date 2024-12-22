#!/bin/bash

# VNC and XRDP Install Script
# Usage: ./vnc_xrdp_install.sh

set -e

# Colors for output
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

# Function to prompt for OS selection
select_os_version() {
    echo -e "${YELLOW}Please select your operating system:${NO_COLOR}"
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

# Function to install XRDP and VNC on Ubuntu-based systems
install_ubuntu() {
    echo -e "${YELLOW}Installing XRDP and VNC on Ubuntu-based system...${NO_COLOR}"

    # Update system
    sudo apt-get update

    # Install XFCE and XRDP
    sudo apt-get install -y xfce4 xfce4-goodies xrdp

    # Install VNC server
    sudo apt-get install -y tightvncserver

    # Start XRDP service
    sudo systemctl start xrdp
    sudo systemctl enable xrdp

    # Configure Firewall for XRDP and VNC
    sudo ufw allow 3389/tcp # RDP port
    sudo ufw allow 5901/tcp # VNC port

    echo -e "${YELLOW}XRDP and VNC installation on Ubuntu-based system completed.${NO_COLOR}"
}

# Function to install XRDP and VNC on Red Hat-based systems
install_redhat() {
    echo -e "${YELLOW}Installing XRDP and VNC on Red Hat-based system...${NO_COLOR}"

    # Install EPEL repository for extra packages
    sudo yum install -y epel-release

    # Install XFCE and XRDP
    sudo yum groupinstall -y "Xfce"
    sudo yum install -y xrdp

    # Install VNC server
    sudo yum install -y tigervnc-server

    # Start XRDP service
    sudo systemctl start xrdp
    sudo systemctl enable xrdp

    # Configure Firewall for XRDP and VNC
    sudo firewall-cmd --permanent --add-port=3389/tcp # RDP port
    sudo firewall-cmd --permanent --add-port=5901/tcp # VNC port
    sudo firewall-cmd --reload

    echo -e "${YELLOW}XRDP and VNC installation on Red Hat-based system completed.${NO_COLOR}"
}

# Function to install XRDP and VNC on Fedora-based systems
install_fedora() {
    echo -e "${YELLOW}Installing XRDP and VNC on Fedora system...${NO_COLOR}"

    # Update system
    sudo dnf install -y epel-release

    # Install XFCE and XRDP
    sudo dnf groupinstall -y "Xfce"
    sudo dnf install -y xrdp

    # Install VNC server
    sudo dnf install -y tigervnc-server

    # Start XRDP service
    sudo systemctl start xrdp
    sudo systemctl enable xrdp

    # Configure Firewall for XRDP and VNC
    sudo firewall-cmd --permanent --add-port=3389/tcp # RDP port
    sudo firewall-cmd --permanent --add-port=5901/tcp # VNC port
    sudo firewall-cmd --reload

    echo -e "${YELLOW}XRDP and VNC installation on Fedora system completed.${NO_COLOR}"
}

# Main script
echo
echo -e "${YELLOW}##########################################################################"
echo -e "   XRDP and VNC Installer"
echo -e "##########################################################################${NO_COLOR}"
echo

# Prompt for OS selection
select_os_version

# Execute the appropriate installation based on the selected OS
case $os_version in
    ubuntu|linuxmint|popos)
        install_ubuntu
        ;;
    rhel)
        install_redhat
        ;;
    fedora)
        install_fedora
        ;;
    *)
        echo "Invalid OS selection. Exiting..."
        exit 1
        ;;
esac

echo -e "${YELLOW}XRDP and VNC installation and setup completed successfully.${NO_COLOR}"
exit 0
