#!/bin/bash

# Enable error handling
set -e

# File paths
YML_FILE="docker-swarm-compose.yml"
ENV_FILE="versions.env"

# Check if files exist
if [[ ! -f "$YML_FILE" || ! -f "$ENV_FILE" ]]; then
    echo "Error: Missing $YML_FILE or $ENV_FILE"
    exit 1
fi

# Extract environment variable tag mappings from versions.env
declare -A TAGS
while IFS='=' read -r key value; do
    if [[ "$key" == *_TAG ]]; then
        TAGS["$key"]=$(echo "$value" | xargs)  # Trim whitespace
    fi
done < "$ENV_FILE"

# Extract image paths and variable references from the YML file
IMAGES=$(grep -oP 'image: [^ ]+' "$YML_FILE" | sed 's/image: //')

# Pull images
for IMAGE in $IMAGES; do
    # Extract base image and tag variable (e.g., "${ELASTICSEARCH_TAG}")
    BASE_IMAGE=$(echo "$IMAGE" | sed -E 's/:\$\{[^}]+\}//')
    TAG_VARIABLE=$(echo "$IMAGE" | grep -oP '(?<=\$\{)[^}]+')

    # Resolve the tag from the versions.env file
    if [[ -n "$TAG_VARIABLE" && -n "${TAGS[${TAG_VARIABLE}]}" ]]; then
        TAG="${TAGS[$TAG_VARIABLE]}"
        FULL_IMAGE="$BASE_IMAGE:$TAG"

        # Pull the image
        echo "Pulling image: $FULL_IMAGE"
        sudo docker pull "$FULL_IMAGE"
    else
        echo "Warning: Tag for $IMAGE not found in $ENV_FILE. Skipping..."
    fi
done

echo "All images processed successfully!"
