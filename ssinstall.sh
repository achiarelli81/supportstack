#!/bin/bash

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NO_COLOR='\033[0m'

# Function to display a banner
display_banner() {
    local banner_text="$1"
    echo -e "${CYAN}"
    echo "##########################################################################"
    echo "####                                                                  ####"
    printf "####      ${WHITE}%-58s${CYAN}####\n" "$banner_text"
    echo "####                                                                  ####"
    echo "##########################################################################"
    echo -e "${NO_COLOR}"
}

# Function to select OS version
select_os_version() {
    display_banner "Operating System Selection"
    echo -e "${CYAN}Please select your operating system:${NO_COLOR}"
    echo "1) Fedora"
    echo "2) Ubuntu"
    echo "3) Linux Mint"
    echo "4) Pop!_OS"
    echo "5) RHEL-based (Red Hat, CentOS, AlmaLinux, etc.)"
    echo "6) Exit"

    read -p "Enter your choice (1-6): " os_choice

    case $os_choice in
        1) os_version="fedora" ;;
        2) os_version="ubuntu" ;;
        3) os_version="linuxmint" ;;
        4) os_version="popos" ;;
        5) os_version="rhel" ;;
        6)
            echo -e "${RED}Exiting... Goodbye!${NO_COLOR}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NO_COLOR}"
            select_os_version
            ;;
    esac

    echo -e "${GREEN}Selected OS: $os_version${NO_COLOR}"
}

# Function to remove old STI directory and download support stack scripts
# Function for SS Downloader
ss_downloader() {
    display_banner "Support Stack Scripts Downloader"
    local STI_DIR="/home/$USER/STI"
    local BASE_URL="https://adamchiarelli.net/docker"
    local IMAGES_DIR="/home/$USER/images"
    local DCM4CHE_DIR="/home/$USER/dcm4che"

    echo -e "${YELLOW}Removing old STI directory...${NO_COLOR}"
    sudo rm -rf "$STI_DIR"
    mkdir -p "$STI_DIR"
    cd "$STI_DIR" || exit 1

    echo "Downloading support tools scripts..."
    local scripts=("support-tools-upgrade.sh" "curie_prep.sh" "support-tools-setup.sh" \
                   "setup-support-nodes.sh" "vnc_xrdp_install.sh" "pull_curie_images.sh" \
                   "dicom_send.sh" "hemidall_setup.sh")

    for script in "${scripts[@]}"; do
        wget "$BASE_URL/$script" -q --show-progress -O "$script" || {
            echo -e "${RED}Failed to download $script.${NO_COLOR}"
            exit 1
        }
    done
    chmod +x "$STI_DIR"/*

    # Optional downloads for images and dcm4che
    download_optional() {
        local prompt=$1
        local dir=$2
        local url=$3
        sudo rm -rf "$dir"
        mkdir -p "$dir"
        read -p "$prompt (y/n): " response
        if [ "$response" = "y" ]; then
            cd "$dir" || exit 1
            wget "$url" -q --show-progress || {
                echo -e "${RED}Failed to download $(basename $url).${NO_COLOR}"
                exit 1
            }
            unzip "$(basename $url)"
            sudo rm -rf __MACOSX
            chmod +x "$dir"/*
        fi
    }

    download_optional "Download images?" "$IMAGES_DIR" "$BASE_URL/images/images.zip"
    download_optional "Download dcm4che?" "$DCM4CHE_DIR" "https://adamchiarelli.net/pushfolder/dcm4che-5.24.1.zip"

    echo -e "${GREEN}Support stack scripts downloaded successfully.${NO_COLOR}"
}


# Function to prepare the system
prep_process() {
    display_banner "System Preparation"
    select_os_version

    echo "Updating system and installing required packages..."
    case $os_version in
        fedora) sudo dnf install -y curl docker-compose unzip ;;
        ubuntu|linuxmint|popos) sudo apt-get install -y curl docker-compose unzip ;;
        rhel) sudo yum install -y curl docker-compose unzip ;;
    esac

    # Prompt to install Docker using get-docker.sh
    while true; do
        read -p "Do you want to run the Docker installation script (get-docker.sh)? (yes/no): " docker_choice
        case $docker_choice in
            yes)
                echo "Running Docker installation script..."
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                echo "Restarting Docker service..."
                sudo systemctl restart docker
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}Docker installed and restarted successfully.${NO_COLOR}"
                else
                    echo -e "${RED}Failed to install or restart Docker.${NO_COLOR}"
                fi
                break
                ;;
            no)
                echo -e "${YELLOW}Skipping Docker installation.${NO_COLOR}"
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please answer yes or no.${NO_COLOR}"
                ;;
        esac
    done

    echo "Enabling Docker to start on boot..."
    sudo systemctl enable docker
    echo -e "${GREEN}System preparation complete.${NO_COLOR}"
}

# Function for Docker Swarm setup
docker_swarm_setup() {
    display_banner "Docker Swarm Setup"

    # Check if a swarm is already initialized
    if sudo docker info | grep -q "Swarm: active"; then
        echo -e "${YELLOW}A Docker Swarm is already active.${NO_COLOR}"
        read -p "Do you want to reinitialize the swarm? (yes/no/skip): " swarm_choice
        case $swarm_choice in
            skip)
                echo -e "${YELLOW}Skipping Docker Swarm setup.${NO_COLOR}"
                return
                ;;
            no)
                echo -e "${YELLOW}Swarm setup aborted.${NO_COLOR}"
                return
                ;;
            yes)
                echo -e "${YELLOW}Proceeding with Docker Swarm reinitialization.${NO_COLOR}"
                ;;
            *)
                echo -e "${RED}Invalid choice. Please choose yes, no, or skip.${NO_COLOR}"
                return
                ;;
        esac
    fi

    # Prompt for VMware or non-VMware setup
    echo "Is this a VMware environment?"
    echo "1) Yes (VMware commands)"
    echo "2) No (Standard Swarm commands)"
    read -p "Enter your choice (1-2): " vm_choice

    if [[ "$vm_choice" == "1" ]]; then
        echo "You selected VMware environment."
        read -p "Enter your IP address to initialize Swarm: " IP_ADDRESS
        sudo docker swarm init --advertise-addr "$IP_ADDRESS" --data-path-port 1234
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker Swarm initialized for VMware successfully.${NO_COLOR}"
        else
            echo -e "${RED}Failed to initialize Docker Swarm for VMware.${NO_COLOR}"
            return
        fi

        echo "Disabling TX offload on the Docker bridge network..."
        sudo ethtool -K docker_gwbridge tx off
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}TX offload disabled on docker_gwbridge.${NO_COLOR}"
        else
            echo -e "${RED}Failed to disable TX offload.${NO_COLOR}"
        fi

    elif [[ "$vm_choice" == "2" ]]; then
        echo "You selected Non-VMware environment."
        read -p "Enter your IP address to initialize Swarm: " IP_ADDRESS
        sudo docker swarm init --advertise-addr "$IP_ADDRESS"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker Swarm initialized successfully.${NO_COLOR}"
        else
            echo -e "${RED}Failed to initialize Docker Swarm.${NO_COLOR}"
            return
        fi
    else
        echo -e "${RED}Invalid choice. Please select 1 or 2.${NO_COLOR}"
        return
    fi

    # Node labeling
    while true; do
        read -p "Do you want to label a Docker Swarm node? (yes/no): " label_yn
        if [[ "$label_yn" == "yes" ]]; then
            read -p "Enter the node hostname: " NODE_HOSTNAME
            read -p "Enter the node label (e.g., node1): " NODE_LABEL
            sudo docker node update --label-add nodeName="$NODE_LABEL" "$NODE_HOSTNAME"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Node labeled successfully with nodeName=${NODE_LABEL}.${NO_COLOR}"
            else
                echo -e "${RED}Failed to label the node. Please verify inputs.${NO_COLOR}"
            fi
        else
            echo -e "${YELLOW}Node labeling process completed.${NO_COLOR}"
            break
        fi
    done
}


# Function for Support Tools setup
setup_support_tools() {
    display_banner "Support Tools Setup"
    echo "Setting up support tools..."
    sudo rm -rf /home/$USER/support-tools
    sudo mkdir -p /home/$USER/support-tools
    sudo chmod 755 /home/$USER/support-tools
    sudo chown -R $USER /home/$USER/support-tools
    cd /home/$USER/support-tools || exit 1
    wget http://adamchiarelli.net/docker/support_stack_1.1.2.zip
    unzip -d /home/$USER/support-tools /home/$USER/support-tools/support_stack_1.1.2.zip
    echo -e "${GREEN}Support tools setup complete.${NO_COLOR}"
}

# Function for node setup
setup_nodes() {
    display_banner "Node Setup"
    echo "Creating directories for nodes..."
    local dirs=(
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

    for dir in "${dirs[@]}"; do
        sudo mkdir -p "$dir"
    done

    sudo chown -R $USER:root /media/docker
    sudo chmod 755 /media/docker
    sudo chmod 777 /media/docker/mirth
    cleanup_swarm_images
    # Setup Wireshark container
    echo "Setting up Wireshark container..."
    sudo docker stop wireshark
    sudo docker rm wireshark
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
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Wireshark container set up successfully.${NO_COLOR}"
    else
        echo -e "${RED}Failed to set up Wireshark container.${NO_COLOR}"
    fi

    # Stop Wireshark container after setup
    echo "Stopping Wireshark container..."
    sudo docker stop wireshark
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Wireshark container stopped successfully.${NO_COLOR}"
    else
        echo -e "${RED}Failed to stop Wireshark container.${NO_COLOR}"
    fi

    echo -e "${GREEN}Node setup complete.${NO_COLOR}"
}

# Function for Hemidall configuration
hemidall_config() {
    display_banner "Hemidall Configuration"
    if [ -f "/home/$USER/STI/hemidall_setup.sh" ]; then
        cd /home/$USER/STI/ && ./hemidall_setup.sh
    else
        echo -e "${RED}Hemidall configuration script not found!${NO_COLOR}"
    fi
}
# Function for Docker Image cleanup
cleanup_swarm_images() {
    display_banner "Support-Tools Docker Swarm Image Cleanup"

    echo -e "${YELLOW}Fetching services in the 'support-tools' stack...${NO_COLOR}"
    SERVICES=$(sudo docker stack services support-tools --format "{{.Name}}")

    if [ -z "$SERVICES" ]; then
        echo -e "${RED}No services found in the 'support-tools' stack. Exiting...${NO_COLOR}"
        return
    fi

    echo -e "${GREEN}Services found in the 'support-tools' stack:${NO_COLOR}"
    echo "$SERVICES"

    # Iterate over each service in the stack to find associated images
    for SERVICE in $SERVICES; do
        echo -e "${YELLOW}Processing service: $SERVICE${NO_COLOR}"

        # Get the image used by the service
        IMAGE=$(sudo docker service inspect --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' "$SERVICE")

        if [ -n "$IMAGE" ]; then
            echo -e "${GREEN}Image used by $SERVICE: $IMAGE${NO_COLOR}"

            # Check if any containers are using this image
            CONTAINERS=$(sudo docker ps -a --filter "ancestor=$IMAGE" --format "{{.ID}}")

            if [ -n "$CONTAINERS" ]; then
                echo -e "${YELLOW}Stopping and removing containers for image: $IMAGE${NO_COLOR}"
                sudo docker stop $CONTAINERS
                sudo docker rm $CONTAINERS
            fi

            # Remove the image
            echo -e "${YELLOW}Removing image: $IMAGE${NO_COLOR}"
            sudo docker rmi "$IMAGE"
        else
            echo -e "${RED}No image found for service: $SERVICE${NO_COLOR}"
        fi
    done

    echo -e "${GREEN}Swarm image cleanup for 'support-tools' completed successfully.${NO_COLOR}"
}
# Function for New Installation
new_installation() {
    display_banner "New Installation"
    download_support_stack
    prep_process
    docker_swarm_setup
    setup_support_tools
    setup_nodes
    echo -e "${GREEN}New installation complete.${NO_COLOR}"
}

# Function for Upgrade Process
upgrade_process() {
    display_banner "Upgrade Process"
    echo -e "${YELLOW}Starting the upgrade process...${NO_COLOR}"

    # Step 1: Clean up old files and containers
    echo -e "${YELLOW}Cleaning up old files and containers...${NO_COLOR}"
    sleep 10
    cd ~ || exit 1
    sudo rm -rf \
        /media/docker/viewer-dist \
        /media/docker/portainer \
        /media/docker/shared \
        /media/docker/hemidall \
        /home/$USER/support-tools \
        /media/docker/glances \
        /home/$USER/support-tools-setup.sh
    sudo docker system prune -f
    sleep 15
    echo -e "${GREEN}Cleanup completed successfully.${NO_COLOR}"

    # Step 2: Download the latest support stack scripts
    download_support_stack

    # Step 3: Prepare the system (prompt for Docker installation)
    prep_process

    # Step 4: Reconfigure Docker Swarm (with skip option)
    docker_swarm_setup

    # Step 5: Set up support tools
    setup_support_tools

    # Step 6: Reconfigure nodes, including Wireshark
    setup_nodes

    # Final Step: Ensure Docker Swarm is started
    echo -e "${CYAN}Ensuring Docker Swarm is active...${NO_COLOR}"
    if sudo docker info | grep -q "Swarm: active"; then
        echo -e "${GREEN}Docker Swarm is already active.${NO_COLOR}"
    else
        read -p "Swarm is not active. Would you like to initialize it now? (yes/no): " swarm_start
        if [[ "$swarm_start" == "yes" ]]; then
            read -p "Enter your IP address to initialize Swarm: " IP_ADDRESS
            sudo docker swarm init --advertise-addr "$IP_ADDRESS"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Docker Swarm initialized successfully.${NO_COLOR}"
            else
                echo -e "${RED}Failed to initialize Docker Swarm.${NO_COLOR}"
            fi
        else
            echo -e "${YELLOW}Skipping Swarm initialization.${NO_COLOR}"
        fi
    fi

    # Display completion message
    echo -e "${GREEN}Upgrade process completed successfully.${NO_COLOR}"
}

# Main menu
while true; do
    display_banner "Main Menu"
    echo -e "${WHITE}1) Install Support Tools${NO_COLOR}"
    echo -e "${WHITE}2) Upgrade Support Tools${NO_COLOR}"
    echo -e "${WHITE}3) Setup Support Tools${NO_COLOR}"
    echo -e "${WHITE}4) Setup Nodes${NO_COLOR}"
    echo -e "${WHITE}5) Configure Docker Swarm & Label Nodes${NO_COLOR}"
    echo -e "${WHITE}6) Install Hemidall${NO_COLOR}"
    echo -e "${WHITE}7) Cleanup Support Stack Docker Images${NO_COLOR}"
    echo -e "${WHITE}8) SS Downloander${NO_COLOR}"
    echo -e "${WHITE}9) Exit${NO_COLOR}"

    read -p "Enter your choice (1-9): " choice
    case $choice in
        1) new_installation ;;
        2) upgrade_process ;;
        3) setup_support_tools ;;
        4) setup_nodes ;;
        5) docker_swarm_setup ;;
        6) hemidall_config ;;
        7) cleanup_swarm_images ;;
        8) ss_downloader ;;
        9) echo -e "${RED}Exiting script. Goodbye!${NO_COLOR}" ; exit 0 ;;
        *) echo -e "${RED}Invalid choice. Please try again.${NO_COLOR}" ;;
    esac
done
