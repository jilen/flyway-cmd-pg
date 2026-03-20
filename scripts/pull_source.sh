
#!/usr/bin/env bash
set -e

# Check if tag is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <flyway-tag>"
    echo "Example: $0 flyway-12.1.1"
    exit 1
fi

TAG="$1"
REPO_URL="https://github.com/flyway/flyway.git"
SOURCE_PATH="flyway-commandline/src"
DEST_DIR="$(pwd)/commandline/src"

# Create a temporary directory
TMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TMP_DIR"

# Cleanup function
cleanup() {
    echo "Cleaning up temporary directory..."
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Cloning $REPO_URL at tag $TAG (shallow clone)..."
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$TMP_DIR"

# Clean and create destination directory
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

echo "Copying $SOURCE_PATH to $DEST_DIR..."
cp -r "$TMP_DIR/$SOURCE_PATH"/* "$DEST_DIR/"

echo "Successfully pulled source code to $DEST_DIR"
