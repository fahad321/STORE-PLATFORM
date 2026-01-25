#!/bin/bash

# Create GraphQL Persisted Query via API
# This script creates the persisted query using AEM's GraphQL API

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
AEM_AUTHOR_HOST=${AEM_AUTHOR_HOST:-localhost}
AEM_AUTHOR_PORT=${AEM_AUTHOR_PORT:-4502}
AEM_USER=${AEM_USER:-admin}
AEM_PASSWORD=${AEM_PASSWORD:-admin}
AEM_AUTHOR_URL="http://${AEM_AUTHOR_HOST}:${AEM_AUTHOR_PORT}"

# GraphQL configuration
PROJECT_NAME="store-platform"
QUERY_NAME="homePageByPath"
QUERY_PATH="${PROJECT_NAME}/${QUERY_NAME}"

# GraphQL query
GRAPHQL_QUERY='query HomePageByPath($path: String!) {
  homePageByPath(_path: $path) {
    item {
      _path
      title {
        value
      }
      heroTitle {
        value
      }
      heroSubtitle {
        value
      }
    }
  }
}'

echo "🔧 Creating GraphQL Persisted Query..."
echo ""

# Check if AEM Author is accessible
echo "🔍 Checking AEM Author instance at $AEM_AUTHOR_URL..."
if ! curl -s -f -u "${AEM_USER}:${AEM_PASSWORD}" "${AEM_AUTHOR_URL}/system/console/bundles.json" > /dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to AEM Author at $AEM_AUTHOR_URL${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AEM Author instance is reachable${NC}"
echo ""

# Create persisted query via GraphQL API
echo "📤 Creating persisted query: ${QUERY_PATH}..."

# AEM GraphQL persisted query creation endpoint
# Try persist.json first, then fallback to direct JCR path
CREATE_URL="${AEM_AUTHOR_URL}/graphql/persist.json/${QUERY_PATH}"
ALTERNATE_URL="${AEM_AUTHOR_URL}/conf/store-platform/settings/graphql/persistentQueries/${QUERY_NAME}"

# Create the persisted query using GraphQL persist API
echo "   Using GraphQL persist API..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -u "${AEM_USER}:${AEM_PASSWORD}" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d "{\"query\": $(echo "$GRAPHQL_QUERY" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))")}" \
    "$CREATE_URL" 2>/dev/null)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
    echo -e "${GREEN}✅ Persisted query created successfully (HTTP $HTTP_CODE)${NC}"
    echo ""
    echo "Response:"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
elif [ "$HTTP_CODE" == "409" ]; then
    echo -e "${YELLOW}⚠️  Persisted query already exists (HTTP $HTTP_CODE)${NC}"
    echo "   Updating existing query..."
    
    # Try to update
    UPDATE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -u "${AEM_USER}:${AEM_PASSWORD}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"query\": $(echo "$GRAPHQL_QUERY" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))")}" \
        "$CREATE_URL" 2>/dev/null)
    
    UPDATE_HTTP_CODE=$(echo "$UPDATE_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    if [ "$UPDATE_HTTP_CODE" == "200" ] || [ "$UPDATE_HTTP_CODE" == "201" ]; then
        echo -e "${GREEN}✅ Persisted query updated successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Update response: HTTP $UPDATE_HTTP_CODE${NC}"
    fi
else
    echo -e "${RED}❌ Failed to create persisted query (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
    exit 1
fi

echo ""

# Verify the query exists
echo "🔍 Verifying persisted query..."
VERIFY_URL="${AEM_AUTHOR_URL}/graphql/execute.json/${QUERY_PATH}?path=/content/dam/store-platform/content-fragments/home"
VERIFY_RESPONSE=$(curl -s -u "${AEM_USER}:${AEM_PASSWORD}" "$VERIFY_URL" 2>/dev/null)

if echo "$VERIFY_RESPONSE" | grep -q "homePageByPath\|errors"; then
    if echo "$VERIFY_RESPONSE" | grep -q "errors"; then
        echo -e "${YELLOW}⚠️  Query exists but may have execution errors${NC}"
        echo "Response:"
        echo "$VERIFY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VERIFY_RESPONSE"
    else
        echo -e "${GREEN}✅ Persisted query verified and executable${NC}"
        echo "Response preview:"
        echo "$VERIFY_RESPONSE" | python3 -m json.tool 2>/dev/null | head -20 || echo "$VERIFY_RESPONSE" | head -20
    fi
else
    echo -e "${YELLOW}⚠️  Could not verify query execution${NC}"
fi

echo ""
echo -e "${GREEN}✅ Persisted query creation complete${NC}"
echo ""
echo "GraphQL Endpoint:"
echo "  ${AEM_AUTHOR_URL}/graphql/execute.json/${QUERY_PATH}?path=/content/dam/store-platform/content-fragments/home"

