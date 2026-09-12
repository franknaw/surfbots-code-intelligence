#!/bin/bash
set -e

# Package validation script for Surfbots Dev Platform releases
# Ensures no private source code or secrets are included

ARCHIVE="$1"

if [ -z "$ARCHIVE" ]; then
    ARCHIVE="surfbots-dev-platform-v0.4.0.tar.gz"
fi

if [ ! -f "$ARCHIVE" ]; then
    echo "ERROR: Archive not found: $ARCHIVE"
    exit 1
fi

echo "=== Validating package: $ARCHIVE ==="
echo ""

# Create temp directory for extraction
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Extract archive - files are at root level
echo "Extracting archive..."
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

EXTRACTED_DIR="$TMP_DIR"

echo "Extracted to: $EXTRACTED_DIR"
echo ""

FAILED=0

# Check for forbidden patterns
echo "=== Checking for forbidden patterns ==="

# 1. .env files
echo -n "1. .env files... "
if find "$EXTRACTED_DIR" -name '.env' -type f 2>/dev/null | grep -q .; then
    echo "FAIL - .env files found"
    FAILED=1
else
    echo "PASS"
fi

# 2. Private source directories
echo -n "2. src/ directory... "
if [ -d "$EXTRACTED_DIR/src" ]; then
    echo "FAIL - src/ directory found"
    FAILED=1
else
    echo "PASS"
fi

# 3. app/ directories (private source)
echo -n "3. app/ directories... "
if find "$EXTRACTED_DIR" -name 'app' -type d 2>/dev/null | grep -q .; then
    echo "FAIL - app/ directories found"
    FAILED=1
else
    echo "PASS"
fi

# 4. tests/
echo -n "4. tests/ directory... "
if [ -d "$EXTRACTED_DIR/tests" ]; then
    echo "FAIL - tests/ directory found"
    FAILED=1
else
    echo "PASS"
fi

# 5. test files
echo -n "5. test files... "
if find "$EXTRACTED_DIR" -name '*test*.py' -o -name 'test_*' 2>/dev/null | grep -q .; then
    echo "FAIL - test files found"
    FAILED=1
else
    echo "PASS"
fi

# 6. __pycache__
echo -n "6. __pycache__... "
if find "$EXTRACTED_DIR" -name '__pycache__' -type d 2>/dev/null | grep -q .; then
    echo "FAIL - __pycache__ found"
    FAILED=1
else
    echo "PASS"
fi

# 7. .pytest_cache
echo -n "7. .pytest_cache... "
if find "$EXTRACTED_DIR" -name '.pytest_cache' -type d 2>/dev/null | grep -q .; then
    echo "FAIL - .pytest_cache found"
    FAILED=1
else
    echo "PASS"
fi

# 8. .github
echo -n "8. .github... "
if [ -d "$EXTRACTED_DIR/.github" ]; then
    echo "FAIL - .github found"
    FAILED=1
else
    echo "PASS"
fi

# 9. .clinerules
echo -n "9. .clinerules... "
if [ -d "$EXTRACTED_DIR/.clinerules" ]; then
    echo "FAIL - .clinerules found"
    FAILED=1
else
    echo "PASS"
fi

# 10. Required files
echo ""
echo "=== Checking required files ==="

REQUIRED_FILES=("VERSION" "manifest.json" "bootstrap.sh" "cluster.sh" "surfbots-admin.sh" "helm" "scripts" "docs")

for file in "${REQUIRED_FILES[@]}"; do
    echo -n "  $file... "
    if [ -e "$EXTRACTED_DIR/$file" ]; then
        echo "OK"
    else
        echo "MISSING"
        FAILED=1
    fi
done

# 11. Check VERSION format
echo ""
echo "=== Checking VERSION format ==="
if [ -f "$EXTRACTED_DIR/VERSION" ]; then
    VERSION=$(cat "$EXTRACTED_DIR/VERSION")
    echo "VERSION: $VERSION"
    if [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "  Format: PASS"
    else
        echo "  Format: FAIL (expected v0.4.0)"
        FAILED=1
    fi
else
    echo "  MISSING: FAIL"
    FAILED=1
fi

# Final result
echo ""
echo "=== Validation Result ==="
if [ $FAILED -eq 0 ]; then
    echo "PASS: Package validation successful"
    exit 0
else
    echo "FAIL: Package validation failed"
    exit 1
fi
