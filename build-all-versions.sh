#!/bin/bash

# PostgreSQL versions to build
declare -A POSTGRES_VERSIONS=(
    ["18"]="18.1 18 latest 18.1-trixie 18-trixie trixie 18.1-bookworm 18-bookworm bookworm "
    ["17"]="17.7 17 17.7-trixie 17-trixie 17.7-bookworm 17-bookworm"
)

# Function to check if Docker image already exists
image_exists() {
    local image_tag=$1
    echo "Checking if image pshaddel/postgres-pgtap:$image_tag already exists..."

    # Use docker manifest inspect to check if image exists (works for multi-platform images)
    if docker manifest inspect "pshaddel/postgres-pgtap:$image_tag" >/dev/null 2>&1; then
        echo "✓ Image pshaddel/postgres-pgtap:$image_tag already exists"
        return 0
    else
        echo "✗ Image pshaddel/postgres-pgtap:$image_tag does not exist"
        return 1
    fi
}

# Function to check if any tags for a version need to be built
needs_building() {
    local tags=$1
    local needs_build=false

    for tag in $tags; do
        if ! image_exists "$tag"; then
            needs_build=true
            break
        fi
    done

    if [ "$needs_build" = true ]; then
        return 0  # Needs building
    else
        return 1  # All images exist
    fi
}

# Function to build and push a specific version
build_version() {
    local base_version=$1
    local tags=$2

    echo "Checking PostgreSQL $base_version with tags: $tags"

    # Check if this version needs building
    if ! needs_building "$tags"; then
        echo "All images for PostgreSQL $base_version already exist, skipping build."
        echo "----------------------------------------"
        return 0
    fi

    echo "Building PostgreSQL $base_version with tags: $tags"

    # Create temporary Dockerfile for this version
    local dockerfile_temp="Dockerfile.${base_version}"

    # Determine the pgTAP package name based on major version
    local major_version=$(echo $base_version | cut -d. -f1)

    # For PostgreSQL 18, use postgresql-17-pgtap as 18-pgtap is not available yet
    if [ "$major_version" = "18" ]; then
        local pgtap_package="postgresql-17-pgtap"
    else
        local pgtap_package="postgresql-${major_version}-pgtap"
    fi

    # Create Dockerfile for this version
    if [ "$major_version" = "18" ]; then
        # Special handling for PostgreSQL 18 - copy pgTAP files from PG17 to PG18 directories
        cat > "$dockerfile_temp" << EOF
# Start with the official PostgreSQL image
FROM postgres:${base_version}

# Install pgTAP using apt (using PG17 package)
RUN apt-get update && apt-get install -y \\
    ${pgtap_package} \\
    && apt-get clean \\
    && rm -rf /var/lib/apt/lists/*

# Copy pgTAP extension files from PG17 to PG18 directories
RUN cp -r /usr/share/postgresql/17/extension/pgtap* /usr/share/postgresql/18/extension/

# enable the extension
RUN echo "CREATE EXTENSION pgtap;" > /docker-entrypoint-initdb.d/01_pgtap.sql

# Expose the PostgreSQL port
EXPOSE 5432
EOF
    else
        cat > "$dockerfile_temp" << EOF
# Start with the official PostgreSQL image
FROM postgres:${base_version}

# Install pgTAP using apt
RUN apt-get update && apt-get install -y \\
    ${pgtap_package} \\
    && apt-get clean \\
    && rm -rf /var/lib/apt/lists/*

# enable the extension
RUN echo "CREATE EXTENSION pgtap;" > /docker-entrypoint-initdb.d/01_pgtap.sql

# Expose the PostgreSQL port
EXPOSE 5432
EOF
    fi

    # Build tag arguments
    local tag_args=""
    for tag in $tags; do
        tag_args="$tag_args --tag pshaddel/postgres-pgtap:$tag"
    done

    # Build and push
    echo "Building with command:"
    echo "docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 $tag_args -f $dockerfile_temp ."

    docker buildx build \
        --push \
        --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
        $tag_args \
        -f "$dockerfile_temp" \
        .

    # Clean up temporary Dockerfile
    rm "$dockerfile_temp"

    echo "Completed building PostgreSQL $base_version"
    echo "----------------------------------------"
}

# Main execution
echo "Starting multi-version PostgreSQL pgTAP builds..."
echo "================================================"

# Build each version
for version in "${!POSTGRES_VERSIONS[@]}"; do
    build_version "$version" "${POSTGRES_VERSIONS[$version]}"
done

echo "All builds completed!"