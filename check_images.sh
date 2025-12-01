#!/bin/bash

# Source the versions from build script
source build-all-versions.sh

# Function to check if Docker image already exists
image_exists() {
    local image_tag=$1
    if docker manifest inspect "pshaddel/postgres-pgtap:$image_tag" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check if any version needs building
needs_any_building=false
for version in "${!POSTGRES_VERSIONS[@]}"; do
    tags="${POSTGRES_VERSIONS[$version]}"
    for tag in $tags; do
        if ! image_exists "$tag"; then
            echo "Image pshaddel/postgres-pgtap:$tag does not exist, building needed"
            needs_any_building=true
            break 2
        fi
    done
done

if [ "$needs_any_building" = true ]; then
    echo "needs_building=true" >> $GITHUB_OUTPUT
else
    echo "needs_building=false" >> $GITHUB_OUTPUT
    echo "All images already exist, no building needed"
fi
