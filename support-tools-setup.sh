#!/bin/bash

# Constants for colors
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

# Print the header
echo
echo -e "${YELLOW}##########################################################################"
echo -e "   Support Tools Setup: 1.1.3"
echo -e "##########################################################################${NO_COLOR}"
echo

# Function to select OS version
select_os_version() {
  echo "Please select your OS version:"
  echo "1) Fedora"
  echo "2) Ubuntu"
  echo "3) Linux Mint"
  echo "4) Pop!_OS"
  echo "5) RHEL-based (Red Hat, CentOS, AlmaLinux, etc.)"
  echo "6) Exit"

  # Read user input
  read -p "Enter your choice (1-6): " os_choice

  case $os_choice in
    1)
      os_version="fedora"
      PACKAGE_MANAGER="sudo dnf"
      PACKAGE_LIST="curl docker-compose inxi nfs-utils openldap-clients sg3-utils nmap iftop ncdu iotop java-1.8.0-openjdk-devel dcmtk ethtool"
      ;;
    2)
      os_version="ubuntu"
      PACKAGE_MANAGER="sudo apt-get"
      PACKAGE_LIST="curl docker-compose inxi nfs-common ldap-utils sg3-utils nmap iftop ncdu iotop default-jdk dcmtk ethtool"
      ;;
    3)
      os_version="linuxmint"
      PACKAGE_MANAGER="sudo apt-get"
      PACKAGE_LIST="curl docker-compose inxi nfs-common ldap-utils sg3-utils nmap iftop ncdu iotop default-jdk dcmtk ethtool"
      ;;
    4)
      os_version="popos"
      PACKAGE_MANAGER="sudo apt-get"
      PACKAGE_LIST="curl docker-compose inxi nfs-common ldap-utils sg3-utils nmap iftop ncdu iotop default-jdk dcmtk ethtool"
      ;;
    5)
      os_version="rhel"
      PACKAGE_MANAGER="sudo yum"
      PACKAGE_LIST="curl docker-compose inxi nfs-utils openldap-clients sg3-utils nmap iftop ncdu iotop java-1.8.0-openjdk-devel dcmtk ethtool"
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

# Run OS selection
select_os_version

# Setup directories and permissions
echo "Setting up support tools directories and permissions..."
sudo rm -rf /home/$USER/support-tools
sudo rm -rf /media/docker/ohif-orthanc
sudo mkdir -p /media/docker/ohif-orthanc
sudo mkdir -p /home/$USER/support-tools
sudo chmod 755 /home/$USER/support-tools
sudo chown -R $USER:$USER /home/$USER/support-tools
sleep 3

# System update and package installation
echo "Updating system and installing required dependencies..."
{
$PACKAGE_MANAGER update -y &> /dev/null
$PACKAGE_MANAGER autoremove -y &> /dev/null
$PACKAGE_MANAGER install -y wget unzip $PACKAGE_LIST &> /dev/null
}
echo "System updated and dependencies installed successfully."
sleep 3

# Download support stack and OHIF Orthanc
echo "Downloading support stack and OHIF Orthanc..."
{
cd /home/$USER/support-tools
wget http://adamchiarelli.net/docker/support_stack_1.1.2.zip -O support_stack_1.1.2.zip &> /dev/null
cd /media/docker/ohif-orthanc
sudo wget http://adamchiarelli.net/docker/ohif-orthanc.zip -O ohif-orthanc.zip &> /dev/null
}
echo "Downloads completed."
sleep 10

# Check downloaded files
echo "Verifying downloaded files..."
ls -al /home/$USER/support-tools
sleep 2

# Set permissions on zip files
echo "Setting permissions on downloaded files..."
{
sudo chmod +x /home/$USER/support-tools/support_stack_1.1.2.zip
sudo chmod +x /media/docker/ohif-orthanc/ohif-orthanc.zip
} &> /dev/null
sleep 3

# Unzip files
echo "Extracting support stack..."
{
sudo unzip -d /home/$USER/support-tools /home/$USER/support-tools/support_stack_1.1.2.zip &> /dev/null
}
sleep 5

echo "Extracting OHIF Orthanc..."
{
sudo unzip -d /media/docker/ohif-orthanc /media/docker/ohif-orthanc/ohif-orthanc.zip &> /dev/null
}
echo "Extraction completed."

# Clean up unnecessary files
echo "Cleaning up unnecessary files..."
{
sudo rm -rf /home/$USER/support-tools/__MACOSX
sudo rm -rf /media/docker/ohif-orthanc/__MACOSX
sudo chmod +x /media/docker/ohif-orthanc/*.*
sudo chmod +x /home/$USER/support-tools/*.sh
sudo chmod +x /home/$USER/support-tools/*.yml
} &> /dev/null
sleep 2

# Function to configure Docker Swarm
configure_swarm() {
    while true; do
        read -p "Do you want to configure this system as a Docker Swarm leader (yes/no)? " yn
        case $yn in
            yes )
                echo "OK, enter your IP in the next prompt..."
                read -p "Enter your IP address: " IP_ADDRESS
                echo "Initializing Docker Swarm with IP address $IP_ADDRESS..."
                sudo docker swarm init --advertise-addr $IP_ADDRESS --data-path-port 1234
                if [ $? -ne 0 ]; then
                    echo "Docker Swarm initialization failed."
                    exit 1
                fi
                echo "Docker Swarm initialized successfully."
                break
                ;;
            no )
                echo "Skipping Swarm setup."
                exit 0
                ;;
            * )
                echo "Invalid response. Please answer yes or no."
                ;;
        esac
    done
}

# Configure Swarm
configure_swarm

# Finish
echo
echo -e "${YELLOW}##########################################################################"
echo -e "   Setup complete. Time for golf!"
echo -e "##########################################################################${NO_COLOR}"
exit
