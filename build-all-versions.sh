#!/bin/bash

# PostgreSQL versions to build
declare -A POSTGRES_VERSIONS=(
    ["19beta1"]="19beta1 19beta1-trixie 19beta1-bookworm"
    ["18"]="18.4 18 latest 18.4-trixie 18-trixie trixie 18.4-bookworm 18-bookworm bookworm "
    ["17"]="17.10 17 17.10-trixie 17-trixie 17.10-bookworm 17-bookworm"
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

# Function to build and push a specific version
build_version() {
    local base_version=$1
    local tags=$2

    echo "Checking PostgreSQL $base_version with tags: $tags"

    # Strict per-tag policy: only push tags that don't already exist on Docker Hub.
    # Floating tags (latest, 18, bookworm, ...) will NOT auto-roll to a newer PG
    # version — delete them on Docker Hub first if you want them to move.
    local missing_tags=()
    for tag in $tags; do
        if ! image_exists "$tag"; then
            missing_tags+=("$tag")
        fi
    done

    if [ ${#missing_tags[@]} -eq 0 ]; then
        echo "All tags for PostgreSQL $base_version already exist, skipping build."
        echo "----------------------------------------"
        return 0
    fi

    echo "Building PostgreSQL $base_version for missing tags: ${missing_tags[*]}"

    # Create temporary Dockerfile for this version
    local dockerfile_temp="Dockerfile.${base_version}"

    # Extract numeric major version (handles "19beta1" → "19", "18.4" → "18")
    local major_version=$(echo "$base_version" | grep -o '^[0-9]*')

    # For PG18+ use postgresql-17-pgtap until a native package ships
    if [ "$major_version" -ge 18 ] 2>/dev/null; then
        local pgtap_package="postgresql-17-pgtap"
    else
        local pgtap_package="postgresql-${major_version}-pgtap"
    fi

    # Create Dockerfile for this version
    if [ "$major_version" -ge 18 ] 2>/dev/null; then
        # Install PG17 pgTAP package and copy extension files into the target PG directory
        cat > "$dockerfile_temp" << EOF
# Start with the official PostgreSQL image
FROM postgres:${base_version}

# Install pgTAP using apt (using PG17 package; native PG${major_version} package not yet available)
RUN apt-get update && apt-get install -y \\
    ${pgtap_package} \\
    && apt-get clean \\
    && rm -rf /var/lib/apt/lists/*

# Copy pgTAP extension files from PG17 to PG${major_version} directories
RUN cp -r /usr/share/postgresql/17/extension/pgtap* /usr/share/postgresql/${major_version}/extension/

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

    # Build tag arguments (only the missing tags)
    local tag_args=""
    for tag in "${missing_tags[@]}"; do
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

# Main execution — only run when this script is executed directly, not when sourced.
# (auto-update.yml sources this file just to load POSTGRES_VERSIONS.)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Starting multi-version PostgreSQL pgTAP builds..."
    echo "================================================"

    for version in "${!POSTGRES_VERSIONS[@]}"; do
        build_version "$version" "${POSTGRES_VERSIONS[$version]}"
    done

    echo "All builds completed!"
fi