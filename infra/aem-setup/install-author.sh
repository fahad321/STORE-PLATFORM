#!/bin/bash

# Install AEM Content Package to Author Instance
# This script builds the package and uploads it to /crx/packmgr/service.jsp

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AEM_DIR="$REPO_ROOT/aem"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "📦 Installing AEM Content Package to Author Instance..."
echo ""

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}❌ Maven is not installed${NC}"
    echo "   Please install Maven: https://maven.apache.org/install.html"
    exit 1
fi

# Check if AEM directory exists
if [ ! -d "$AEM_DIR" ]; then
    echo -e "${RED}❌ AEM directory not found: $AEM_DIR${NC}"
    exit 1
fi

cd "$AEM_DIR"

# AEM Author configuration
AEM_HOST=${AEM_HOST:-localhost}
AEM_PORT=${AEM_PORT:-4502}
AEM_USER=${AEM_USER:-admin}
AEM_PASSWORD=${AEM_PASSWORD:-admin}
AEM_URL="http://${AEM_HOST}:${AEM_PORT}"
PACKMGR_URL="${AEM_URL}/crx/packmgr/service.jsp"

echo "🔍 Checking AEM Author instance at $AEM_URL..."

if ! curl -s -f -u "${AEM_USER}:${AEM_PASSWORD}" "$AEM_URL/system/console/bundles.json" > /dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to AEM Author at $AEM_URL${NC}"
    echo "   Make sure AEM SDK Author instance is running"
    echo "   You can start it with: java -jar aem-sdk-quickstart-author-*.jar"
    exit 1
fi

echo -e "${GREEN}✅ AEM Author instance is reachable${NC}"
echo ""

# Build package
echo "🔨 Building content package..."
mvn clean package

# Find the built package
PACKAGE_FILE=$(find target -name "*.zip" -type f | head -1)

if [ -z "$PACKAGE_FILE" ]; then
    echo -e "${RED}❌ Package file not found in target/ directory${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Package built: $PACKAGE_FILE${NC}"
echo ""

# Upload and install package
echo "📤 Uploading and installing package to Author instance..."
echo "   Package Manager URL: $PACKMGR_URL"

# Upload package using curl
UPLOAD_RESPONSE=$(curl -s -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "file=@${PACKAGE_FILE}" \
    -F "name=$(basename $PACKAGE_FILE)" \
    -F "force=true" \
    -F "install=true" \
    "$PACKMGR_URL")

# Check if installation was successful
if echo "$UPLOAD_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Package installed successfully${NC}"
elif echo "$UPLOAD_RESPONSE" | grep -q '"success":false'; then
    echo -e "${RED}❌ Package installation failed${NC}"
    echo "Response: $UPLOAD_RESPONSE"
    exit 1
else
    # Try to parse response or check HTTP status
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "${AEM_USER}:${AEM_PASSWORD}" \
        -F "file=@${PACKAGE_FILE}" \
        -F "name=$(basename $PACKAGE_FILE)" \
        -F "force=true" \
        -F "install=true" \
        "$PACKMGR_URL" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "${GREEN}✅ Package uploaded (HTTP 200)${NC}"
        echo "   Note: Check AEM Package Manager UI to verify installation status"
    else
        echo -e "${YELLOW}⚠️  Unexpected response (HTTP $HTTP_CODE)${NC}"
        echo "   Response: $UPLOAD_RESPONSE"
    fi
fi

echo ""
echo -e "${GREEN}✅ Installation process complete${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify content at: ${AEM_URL}/content/dam/store-platform/content-fragments/home.html"
echo "  2. Test GraphQL endpoint: ${AEM_URL}/graphql/execute.json/store-platform/homePageByPath?path=/content/dam/store-platform/content-fragments/home"
echo "  3. Run ./verify.sh to verify the installation"
