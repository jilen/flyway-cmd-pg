#!/usr/bin/env bash
set -euo pipefail

METADATA_URL="${FLYWAY_PARENT_METADATA_URL:-https://repo1.maven.org/maven2/org/flywaydb/flyway-parent/maven-metadata.xml}"
REPO_BASE_URL="${FLYWAY_PARENT_REPO_BASE_URL:-https://repo1.maven.org/maven2/org/flywaydb/flyway-parent}"
REPO_URL="${FLYWAY_REPO_URL:-https://github.com/flyway/flyway.git}"
SOURCE_PATH="${FLYWAY_COMMANDLINE_SOURCE_PATH:-flyway-commandline/src}"
DEST_DIR="$(pwd)/commandline/src"
BUILD_FILE="$(pwd)/build.mill"

resolve_latest_version() {
    local metadata_file="$1"
    python3 - "$metadata_file" <<'PY'
import sys
import xml.etree.ElementTree as ET

metadata = ET.parse(sys.argv[1]).getroot()

def text_at(path):
    node = metadata.find(path)
    return node.text.strip() if node is not None and node.text else ""

latest = text_at("./versioning/latest") or text_at("./versioning/release")
if not latest:
    versions = [
        node.text.strip()
        for node in metadata.findall("./versioning/versions/version")
        if node.text and node.text.strip()
    ]
    if not versions:
        raise SystemExit("No versions found in flyway-parent metadata")
    latest = versions[-1]

print(latest)
PY
}

read_parent_versions() {
    local pom_file="$1"
    local flyway_version="$2"
    python3 - "$pom_file" "$flyway_version" <<'PY'
import sys
import xml.etree.ElementTree as ET

pom_file, flyway_version = sys.argv[1], sys.argv[2]
root = ET.parse(pom_file).getroot()

for elem in root.iter():
    if "}" in elem.tag:
        elem.tag = elem.tag.rsplit("}", 1)[1]

properties = root.find("properties")
values = {"flyway": flyway_version}
if properties is not None:
    for child in properties:
        if child.text:
            values[child.tag] = child.text.strip()

print(f"flyway={values['flyway']}")
print(f"lombok={values.get('version.lombok', '')}")
print(f"jackson={values.get('version.jackson', '')}")
print(f"commonsText={values.get('version.commonstext', '')}")
print(f"slf4j={values.get('version.slf4j', '')}")
print(f"postgresql={values.get('version.postgresql', '')}")
print(f"jansi={values.get('version.jansi', '')}")
PY
}

update_mill_versions() {
    local flyway_version="$1"
    local lombok_version="$2"
    local jackson_version="$3"
    local commons_text_version="$4"
    local slf4j_version="$5"
    local postgresql_version="$6"
    local jansi_version="$7"

    python3 - "$BUILD_FILE" "$flyway_version" "$lombok_version" "$jackson_version" "$commons_text_version" "$slf4j_version" "$postgresql_version" "$jansi_version" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
versions = {
    "flyway": sys.argv[2],
    "lombok": sys.argv[3],
    "jackson": sys.argv[4],
    "commonsText": sys.argv[5],
    "slf4j": sys.argv[6],
    "postgresql": sys.argv[7],
    "jansi": sys.argv[8],
}

text = path.read_text()
for key, value in versions.items():
    if value:
        text = re.sub(
            rf'(val\s+{re.escape(key)}\s*=\s*)"[^"]*"',
            rf'\g<1>"{value}"',
            text,
            count=1,
        )
path.write_text(text)
PY
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: $0 [flyway-version|flyway-tag]"
    echo "Example: $0"
    echo "Example: $0 12.1.1"
    echo "Example: $0 flyway-12.1.1"
    exit 0
fi

# Create a temporary directory
TMP_DIR=$(mktemp -d)
CHECKOUT_DIR="$TMP_DIR/flyway"
echo "Created temporary directory: $TMP_DIR"

# Cleanup function
cleanup() {
    echo "Cleaning up temporary directory..."
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Fetching flyway-parent metadata from $METADATA_URL..."
curl -fsSL "$METADATA_URL" -o "$TMP_DIR/maven-metadata.xml"

if [ $# -eq 0 ]; then
    VERSION="$(resolve_latest_version "$TMP_DIR/maven-metadata.xml")"
else
    VERSION="${1#flyway-}"
fi
TAG="flyway-$VERSION"
PARENT_POM_URL="$REPO_BASE_URL/$VERSION/flyway-parent-$VERSION.pom"

echo "Using Flyway version: $VERSION"
echo "Fetching flyway-parent POM from $PARENT_POM_URL..."
curl -fsSL "$PARENT_POM_URL" -o "$TMP_DIR/flyway-parent.pom"

flyway=""
lombok=""
jackson=""
commonsText=""
slf4j=""
postgresql=""
jansi=""
while IFS='=' read -r key value; do
    case "$key" in
        flyway) flyway="$value" ;;
        lombok) lombok="$value" ;;
        jackson) jackson="$value" ;;
        commonsText) commonsText="$value" ;;
        slf4j) slf4j="$value" ;;
        postgresql) postgresql="$value" ;;
        jansi) jansi="$value" ;;
    esac
done < <(read_parent_versions "$TMP_DIR/flyway-parent.pom" "$VERSION")
echo "Updating build.mill dependency versions..."
update_mill_versions "$flyway" "$lombok" "$jackson" "$commonsText" "$slf4j" "$postgresql" "$jansi"

echo "Cloning $REPO_URL at tag $TAG (shallow clone)..."
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$CHECKOUT_DIR"

# Clean and create destination directory
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

echo "Copying $SOURCE_PATH to $DEST_DIR..."
cp -r "$CHECKOUT_DIR/$SOURCE_PATH"/* "$DEST_DIR/"

echo "Successfully pulled source code to $DEST_DIR"
