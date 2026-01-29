#!/bin/bash
set -e

# Script to upload firmware binaries to S3
# Usage: ./upload_firmware_to_s3.sh <version> <dist_dir> <s3_bucket> <s3_endpoint>

VERSION="$1"
DIST_DIR="$2"
S3_BUCKET="$3"
S3_ENDPOINT="$4"

if [ -z "$VERSION" ] || [ -z "$DIST_DIR" ] || [ -z "$S3_BUCKET" ] || [ -z "$S3_ENDPOINT" ]; then
    echo "Usage: $0 <version> <dist_dir> <s3_bucket> <s3_endpoint>"
    exit 1
fi

if [ ! -d "$DIST_DIR" ]; then
    echo "Error: Directory not found at $DIST_DIR"
    exit 1
fi

# Define all firmware files in dist directory
FULL_FW="${DIST_DIR}/full_firmware.bin"
OTA_FW="${DIST_DIR}/ota_firmware.bin"
BOOTLOADER="${DIST_DIR}/bootloader.bin"
PARTITION_TABLE="${DIST_DIR}/partition-table.bin"
OTA_DATA_INITIAL="${DIST_DIR}/ota_data_initial.bin"

# Check required files
if [ ! -f "$FULL_FW" ]; then
    echo "Error: Full firmware file not found at $FULL_FW"
    exit 1
fi

if [ ! -f "$OTA_FW" ]; then
    echo "Error: OTA firmware file not found at $OTA_FW"
    exit 1
fi

echo "=== Uploading Firmware to S3 ==="
echo "Version: $VERSION"
echo "Bucket: $S3_BUCKET"
echo "Endpoint: $S3_ENDPOINT"
echo "Distribution directory: $DIST_DIR"
echo ""
echo "Files to upload:"
echo "  - full_firmware.bin: $([ -f "$FULL_FW" ] && du -h "$FULL_FW" | cut -f1 || echo "not found")"
echo "  - ota_firmware.bin: $([ -f "$OTA_FW" ] && du -h "$OTA_FW" | cut -f1 || echo "not found")"
echo "  - bootloader.bin: $([ -f "$BOOTLOADER" ] && du -h "$BOOTLOADER" | cut -f1 || echo "not found")"
echo "  - partition-table.bin: $([ -f "$PARTITION_TABLE" ] && du -h "$PARTITION_TABLE" | cut -f1 || echo "not found")"
echo "  - ota_data_initial.bin: $([ -f "$OTA_DATA_INITIAL" ] && du -h "$OTA_DATA_INITIAL" | cut -f1 || echo "not found")"

# Extract hostname from endpoint URL
S3_HOST=$(echo "${S3_ENDPOINT}" | sed 's|https://||' | sed 's|http://||')

# Check if s3cmd is available
if ! command -v s3cmd &> /dev/null; then
    echo "Installing s3cmd..."
    pip install s3cmd
fi

echo ""
echo "📦 Uploading firmware to S3..."

# Upload versioned firmware
echo "Uploading full_firmware.bin to firmware/${VERSION}/"
s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
    --secret_key="${S3_SECRET_ACCESS_KEY}" \
    --host="${S3_HOST}" \
    --host-bucket='%(bucket)s.'"${S3_HOST}" \
    put "$FULL_FW" \
    s3://${S3_BUCKET}/firmware/${VERSION}/full_firmware.bin

echo "Uploading ota_firmware.bin to firmware/${VERSION}/"
s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
    --secret_key="${S3_SECRET_ACCESS_KEY}" \
    --host="${S3_HOST}" \
    --host-bucket='%(bucket)s.'"${S3_HOST}" \
    put "$OTA_FW" \
    s3://${S3_BUCKET}/firmware/${VERSION}/ota_firmware.bin

# Upload additional firmware files if they exist
if [ -f "$BOOTLOADER" ]; then
    echo "Uploading bootloader.bin to firmware/${VERSION}/"
    s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
        --secret_key="${S3_SECRET_ACCESS_KEY}" \
        --host="${S3_HOST}" \
        --host-bucket='%(bucket)s.'"${S3_HOST}" \
        put "$BOOTLOADER" \
        s3://${S3_BUCKET}/firmware/${VERSION}/bootloader.bin
fi

if [ -f "$PARTITION_TABLE" ]; then
    echo "Uploading partition-table.bin to firmware/${VERSION}/"
    s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
        --secret_key="${S3_SECRET_ACCESS_KEY}" \
        --host="${S3_HOST}" \
        --host-bucket='%(bucket)s.'"${S3_HOST}" \
        put "$PARTITION_TABLE" \
        s3://${S3_BUCKET}/firmware/${VERSION}/partition-table.bin
fi

if [ -f "$OTA_DATA_INITIAL" ]; then
    echo "Uploading ota_data_initial.bin to firmware/${VERSION}/"
    s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
        --secret_key="${S3_SECRET_ACCESS_KEY}" \
        --host="${S3_HOST}" \
        --host-bucket='%(bucket)s.'"${S3_HOST}" \
        put "$OTA_DATA_INITIAL" \
        s3://${S3_BUCKET}/firmware/${VERSION}/ota_data_initial.bin
fi

# Upload as "latest" for easy access
echo "Uploading full_firmware.bin to firmware/latest/"
s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
    --secret_key="${S3_SECRET_ACCESS_KEY}" \
    --host="${S3_HOST}" \
    --host-bucket='%(bucket)s.'"${S3_HOST}" \
    put "$FULL_FW" \
    s3://${S3_BUCKET}/firmware/latest/full_firmware.bin

echo "Uploading ota_firmware.bin to firmware/latest/"
s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
    --secret_key="${S3_SECRET_ACCESS_KEY}" \
    --host="${S3_HOST}" \
    --host-bucket='%(bucket)s.'"${S3_HOST}" \
    put "$OTA_FW" \
    s3://${S3_BUCKET}/firmware/latest/ota_firmware.bin

# Upload additional firmware files to latest/ if they exist
if [ -f "$BOOTLOADER" ]; then
    echo "Uploading bootloader.bin to firmware/latest/"
    s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
        --secret_key="${S3_SECRET_ACCESS_KEY}" \
        --host="${S3_HOST}" \
        --host-bucket='%(bucket)s.'"${S3_HOST}" \
        put "$BOOTLOADER" \
        s3://${S3_BUCKET}/firmware/latest/bootloader.bin
fi

if [ -f "$PARTITION_TABLE" ]; then
    echo "Uploading partition-table.bin to firmware/latest/"
    s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
        --secret_key="${S3_SECRET_ACCESS_KEY}" \
        --host="${S3_HOST}" \
        --host-bucket='%(bucket)s.'"${S3_HOST}" \
        put "$PARTITION_TABLE" \
        s3://${S3_BUCKET}/firmware/latest/partition-table.bin
fi

if [ -f "$OTA_DATA_INITIAL" ]; then
    echo "Uploading ota_data_initial.bin to firmware/latest/"
    s3cmd --access_key="${S3_ACCESS_KEY_ID}" \
        --secret_key="${S3_SECRET_ACCESS_KEY}" \
        --host="${S3_HOST}" \
        --host-bucket='%(bucket)s.'"${S3_HOST}" \
        put "$OTA_DATA_INITIAL" \
        s3://${S3_BUCKET}/firmware/latest/ota_data_initial.bin
fi

echo ""
echo "✅ Uploaded to S3:"
echo "  - ${S3_ENDPOINT}/${S3_BUCKET}/firmware/${VERSION}/"
echo "  - ${S3_ENDPOINT}/${S3_BUCKET}/firmware/latest/"
