#!/bin/bash

# PostgreSQL versions to build
declare -A POSTGRES_VERSIONS=(
    ["18"]="18.0 18 latest 18.0-trixie 18-trixie trixie 18.0-bookworm 18-bookworm bookworm 18.0-alpine3.22 18-alpine3.22 alpine3.22 18.0-alpine 18-alpine alpine 18.0-alpine3.21 18-alpine3.21 alpine3.21"
    # ["17"]="17.6 17 17.6-trixie 17-trixie 17.6-bookworm 17-bookworm 17.6-alpine3.22 17-alpine3.22 17.6-alpine 17-alpine 17.6-alpine3.21 17-alpine3.21"
)

# Function to build and push a specific version
build_version() {
    local base_version=$1
    local tags=$2

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