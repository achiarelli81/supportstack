#!/bin/bash

# Define color variables
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

# Display header with color
echo
echo -e "${YELLOW}##########################################################################"
echo -e "   Support Stack Scripts Downloader"
echo -e "##########################################################################${NO_COLOR}"
echo

# Variables
USER_HOME="/home/$USER"
STI_DIR="$USER_HOME/STI"
IMAGES_DIR="$USER_HOME/images"
DCM4CHE_DIR="$USER_HOME/dcm4che"
BASE_URL="https://adamchiarelli.net/docker"

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
      os_version="fedora"
      ;;
    2)
      os_version="ubuntu"
      ;;
    3)
      os_version="linuxmint"
      ;;
    4)
      os_version="popos"
      ;;
    5)
      os_version="rhel"
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

# Function to install 'unzip' if missing
install_unzip_if_needed() {
  if ! command -v unzip &> /dev/null; then
    echo "Unzip is not installed."
    read -p "Would you like to install unzip? (y/n): " install_unzip
    if [ "$install_unzip" = "y" ]; then
      case $os_version in
        fedora)
          echo "Installing unzip on Fedora..."
          sudo dnf install -y unzip
          ;;
        ubuntu|linuxmint|popos)
          echo "Installing unzip on Ubuntu-based system..."
          sudo apt-get update && sudo apt-get install -y unzip
          ;;
        rhel)
          echo "Installing unzip on RHEL-based OS..."
          sudo yum install -y unzip
          ;;
        *)
          echo "Unsupported OS. Please install unzip manually."
          exit 1
          ;;
      esac
      echo "Unzip installed successfully."
    else
      echo "Unzip is required for this script. Exiting..."
      exit 1
    fi
  else
    echo "Unzip is already installed. Proceeding..."
  fi
}

# Function to download and verify files
download_file() {
  local url=$1
  local dest=$2
  echo "Downloading $url..."
  wget "$url" -q --show-progress -O "$dest" || { echo "Failed to download $url"; exit 1; }
}

# Prepare directories
setup_directory() {
  local dir=$1
  sudo rm -rf "$dir"
  mkdir -p "$dir"
}

# Prompt OS version
select_os_version

# Main script actions
install_unzip_if_needed
setup_directory "$STI_DIR"
cd "$STI_DIR" || { echo "Failed to change directory to $STI_DIR"; exit 1; }

# Download support tools scripts
scripts=("support-tools-upgrade.sh" "curie_prep.sh" "support-tools-setup.sh" \
"setup-support-nodes.sh" "vnc_xrdp_install.sh" "pull_curie_images.sh" \
"dicom_send.sh" "hemidall_setup.sh")

for script in "${scripts[@]}"; do
  download_file "$BASE_URL/$script" "$script"
done

# Make all scripts executable
sudo chmod +x "$STI_DIR"/*

# Prompt and download additional resources
download_optional() {
  local prompt=$1
  local dir=$2
  local url=$3
  setup_directory "$dir"
  read -p "$prompt (y/n): " response
  if [ "$response" = "y" ]; then
    cd "$dir" || { echo "Failed to change directory to $dir"; exit 1; }
    download_file "$url" "$(basename $url)"
    echo "Unzipping $(basename $url)..."
    unzip "$(basename $url)"
    sudo rm -rf __MACOSX
    sudo chmod +x "$dir"/*
  fi
}

download_optional "Download images?" "$IMAGES_DIR" "$BASE_URL/images/images.zip"
download_optional "Download dcm4che?" "$DCM4CHE_DIR" "https://adamchiarelli.net/pushfolder/dcm4che-5.24.1.zip"

# Exit script
exit
