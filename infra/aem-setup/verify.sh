#!/bin/bash

# Verify AEM Installation
# This script verifies that the AEM content package was installed correctly
# Checks: Publish reachable, GraphQL endpoint, persisted query execution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 Verifying AEM Installation..."
echo ""

# Configuration
AEM_PUBLISH_HOST=${AEM_PUBLISH_HOST:-localhost}
AEM_PUBLISH_PORT=${AEM_PUBLISH_PORT:-4503}
AEM_USER=${AEM_USER:-admin}
AEM_PASSWORD=${AEM_PASSWORD:-admin}
AEM_PUBLISH_URL="http://${AEM_PUBLISH_HOST}:${AEM_PUBLISH_PORT}"

# GraphQL configuration
PROJECT_NAME="store-platform"
QUERY_NAME="homePageByPath"
CONTENT_FRAGMENT_PATH="/content/dam/store-platform/content-fragments/home"

# GraphQL endpoint paths
GRAPHQL_ENDPOINT_PATH="/content/_cq_graphql/${PROJECT_NAME}/${QUERY_NAME}/endpoint.json"
GRAPHQL_EXECUTE_URL="${AEM_PUBLISH_URL}/graphql/execute.json/${PROJECT_NAME}/${QUERY_NAME}?path=${CONTENT_FRAGMENT_PATH}"

# Function to check URL
check_url() {
    local url=$1
    local description=$2
    local auth=${3:-""}
    local show_response=${4:-false}
    
    echo "   Checking: $description"
    echo "   URL: $url"
    
    if [ -n "$auth" ]; then
        HTTP_CODE=$(curl -s -o /tmp/curl_response.txt -w "%{http_code}" -u "$auth" "$url" 2>/dev/null || echo "000")
    else
        HTTP_CODE=$(curl -s -o /tmp/curl_response.txt -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    fi
    
    if [ "$HTTP_CODE" == "000" ]; then
        echo -e "   ${RED}❌ Connection failed${NC}"
        return 1
    elif [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
        echo -e "   ${GREEN}✅ OK (HTTP $HTTP_CODE)${NC}"
        if [ "$show_response" == "true" ]; then
            echo "   Response preview:"
            head -c 200 /tmp/curl_response.txt | sed 's/^/      /'
            echo ""
        fi
        return 0
    else
        echo -e "   ${YELLOW}⚠️  HTTP $HTTP_CODE${NC}"
        if [ "$show_response" == "true" ]; then
            echo "   Response:"
            cat /tmp/curl_response.txt | sed 's/^/      /'
        fi
        return 1
    fi
}

# Check Publish Instance Reachability
echo "📋 Publish Instance Verification ($AEM_PUBLISH_URL)"
echo ""

# Check if Publish is accessible
echo "1️⃣  Checking Publish instance reachability..."
if ! curl -s -f -u "${AEM_USER}:${AEM_PASSWORD}" "${AEM_PUBLISH_URL}/system/console/bundles.json" > /dev/null 2>&1; then
    echo -e "${RED}❌ Publish instance not accessible at $AEM_PUBLISH_URL${NC}"
    echo "   Make sure AEM SDK Publish instance is running"
    exit 1
fi
echo -e "${GREEN}✅ Publish instance is reachable${NC}"
echo ""

# Check GraphQL Endpoint
echo "2️⃣  Checking GraphQL endpoint configuration..."
check_url "${AEM_PUBLISH_URL}${GRAPHQL_ENDPOINT_PATH}" "GraphQL endpoint definition" "${AEM_USER}:${AEM_PASSWORD}" false
ENDPOINT_OK=$?
echo ""

# Check Persisted Query Execution
echo "3️⃣  Checking persisted query execution..."
echo "   Query: ${PROJECT_NAME}/${QUERY_NAME}"
echo "   Path parameter: ${CONTENT_FRAGMENT_PATH}"

# Check if query executes successfully
HTTP_CODE=$(curl -s -o /tmp/graphql_response.json -w "%{http_code}" "${GRAPHQL_EXECUTE_URL}" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "   ${GREEN}✅ Query executed successfully (HTTP $HTTP_CODE)${NC}"
    
    # Check response content
    if [ -f /tmp/graphql_response.json ]; then
        RESPONSE=$(cat /tmp/graphql_response.json)
        echo "   Response preview:"
        echo "$RESPONSE" | head -c 300 | sed 's/^/      /'
        echo ""
        
        # Validate response structure
        if echo "$RESPONSE" | grep -q "homePageByPath"; then
            echo -e "   ${GREEN}✅ Response contains 'homePageByPath'${NC}"
        fi
        
        if echo "$RESPONSE" | grep -q "data"; then
            echo -e "   ${GREEN}✅ Response contains 'data' field${NC}"
        fi
        
        if echo "$RESPONSE" | grep -q "title"; then
            echo -e "   ${GREEN}✅ Response contains 'title' field${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Response may not contain expected 'title' field${NC}"
        fi
    fi
else
    echo -e "   ${RED}❌ Query execution failed (HTTP $HTTP_CODE)${NC}"
    if [ -f /tmp/graphql_response.json ]; then
        echo "   Error response:"
        cat /tmp/graphql_response.json | sed 's/^/      /'
    fi
    exit 1
fi

echo ""

# Summary
echo "📝 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Publish instance: Reachable${NC}"
if [ $ENDPOINT_OK -eq 0 ]; then
    echo -e "${GREEN}✅ GraphQL endpoint: Configured${NC}"
else
    echo -e "${YELLOW}⚠️  GraphQL endpoint: Check failed${NC}"
fi
echo -e "${GREEN}✅ Persisted query: Executable${NC}"
echo ""

echo "📋 GraphQL Endpoint URLs:"
echo ""
echo "Endpoint definition:"
echo "  ${AEM_PUBLISH_URL}${GRAPHQL_ENDPOINT_PATH}"
echo ""
echo "Query execution:"
echo "  ${GRAPHQL_EXECUTE_URL}"
echo ""

echo -e "${GREEN}✅ Verification complete${NC}"

# Cleanup
rm -f /tmp/curl_response.txt /tmp/graphql_response.json
