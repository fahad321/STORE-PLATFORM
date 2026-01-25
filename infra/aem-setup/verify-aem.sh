#!/bin/bash

# AEM Connection Verification Script
# Verifies that AEM environment is properly configured and accessible

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WEB_DIR="$REPO_ROOT/apps/web"
ENV_FILE="$WEB_DIR/.env.local"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Verifying AEM Setup..."
echo ""

# Check if .env.local exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  Warning: $ENV_FILE not found${NC}"
    echo "   Copy env.example to apps/web/.env.local and configure it"
    echo ""
    exit 1
fi

# Source environment variables
set -a
source "$ENV_FILE"
set +a

# Check required variables
echo "📋 Checking environment variables..."

MISSING_VARS=()

if [ -z "$AEM_ENDPOINT" ]; then
    MISSING_VARS+=("AEM_ENDPOINT")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

echo -e "${GREEN}✅ All required environment variables are set${NC}"
echo ""

# Validate AEM_ENDPOINT is a valid URL
echo "🔗 Validating AEM endpoint URL..."
if [[ ! "$AEM_ENDPOINT" =~ ^https?:// ]]; then
    echo -e "${RED}❌ AEM_ENDPOINT must be a valid HTTP/HTTPS URL${NC}"
    echo "   Current value: $AEM_ENDPOINT"
    exit 1
fi

echo -e "${GREEN}✅ AEM_ENDPOINT format is valid${NC}"
echo "   Endpoint: $AEM_ENDPOINT"
echo ""

# Check AEM_MODE
AEM_MODE=${AEM_MODE:-PERSISTED_GET}
if [ "$AEM_MODE" != "PERSISTED_GET" ] && [ "$AEM_MODE" != "GRAPHQL_POST" ]; then
    echo -e "${YELLOW}⚠️  Warning: AEM_MODE should be PERSISTED_GET or GRAPHQL_POST${NC}"
    echo "   Using default: PERSISTED_GET"
    AEM_MODE="PERSISTED_GET"
fi

echo "   Mode: $AEM_MODE"
if [ -n "$AEM_AUTH_HEADER" ]; then
    echo "   Auth: Configured (hidden)"
else
    echo "   Auth: Not configured"
fi
echo ""

# Test AEM connectivity
echo "🌐 Testing AEM connectivity..."

# Prepare headers
HEADERS=()
if [ -n "$AEM_AUTH_HEADER" ]; then
    HEADERS+=(-H "Authorization: $AEM_AUTH_HEADER")
fi

# Test based on mode
if [ "$AEM_MODE" == "PERSISTED_GET" ]; then
    # Test with a simple path parameter
    TEST_URL="${AEM_ENDPOINT}?path=/content/dam/test"
    echo "   Testing GET request to: $TEST_URL"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        "${HEADERS[@]}" \
        "$TEST_URL" 2>/dev/null || echo "000")
else
    # Test GraphQL POST
    TEST_URL="$AEM_ENDPOINT"
    echo "   Testing POST request to: $TEST_URL"
    
    GRAPHQL_QUERY='{"query":"{ __typename }"}'
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        "${HEADERS[@]}" \
        -d "$GRAPHQL_QUERY" \
        "$TEST_URL" 2>/dev/null || echo "000")
fi

if [ "$HTTP_CODE" == "000" ]; then
    echo -e "${RED}❌ Connection failed: Could not reach AEM endpoint${NC}"
    echo "   Check network connectivity and AEM instance status"
    exit 1
elif [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo -e "${GREEN}✅ AEM endpoint is accessible (HTTP $HTTP_CODE)${NC}"
elif [ "$HTTP_CODE" == "401" ] || [ "$HTTP_CODE" == "403" ]; then
    echo -e "${YELLOW}⚠️  Authentication issue (HTTP $HTTP_CODE)${NC}"
    echo "   Verify AEM_AUTH_HEADER is correct"
elif [ "$HTTP_CODE" == "404" ]; then
    echo -e "${YELLOW}⚠️  Endpoint not found (HTTP $HTTP_CODE)${NC}"
    echo "   Verify AEM_ENDPOINT URL is correct"
    echo "   For persisted queries, ensure the query exists in AEM"
else
    echo -e "${YELLOW}⚠️  Unexpected response (HTTP $HTTP_CODE)${NC}"
    echo "   Endpoint may be accessible but check AEM logs for details"
fi

echo ""
echo -e "${GREEN}✅ AEM verification complete${NC}"
echo ""
echo "Next steps:"
echo "  1. Run 'pnpm dev' from the repo root"
echo "  2. Open http://localhost:3000"
echo "  3. Verify content loads from AEM"

