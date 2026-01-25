#!/usr/bin/env bash
set -euo pipefail

AEM_AUTHOR_HOST="${AEM_AUTHOR_HOST:-localhost}"
AEM_AUTHOR_PORT="${AEM_AUTHOR_PORT:-4502}"
AEM_PUBLISH_HOST="${AEM_PUBLISH_HOST:-localhost}"
AEM_PUBLISH_PORT="${AEM_PUBLISH_PORT:-4503}"
AEM_USER="${AEM_USER:-admin}"
AEM_PASSWORD="${AEM_PASSWORD:-admin}"

AUTHOR_URL="http://${AEM_AUTHOR_HOST}:${AEM_AUTHOR_PORT}"
PUBLISH_URL="http://${AEM_PUBLISH_HOST}:${AEM_PUBLISH_PORT}"

CONTENT_FRAGMENT_PATH="/content/dam/store-platform/content-fragments/home"
MODEL_ITEMS_PATH="/crx/server/crx.default/jcr:root/conf/store/settings/dam/cfm/models/homepage/jcr:content/model/cq:dialog/content/items.json"

GRAPHQL_ENDPOINT_PATH="/content/_cq_graphql/store/endpoint.json"
PERSISTED_QUERY_URL="${PUBLISH_URL}/graphql/execute.json/store/homePageByPath;path=${CONTENT_FRAGMENT_PATH}"

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

check_http() {
  local url="$1"
  local label="$2"

  if ! curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" "$url" > /tmp/aem-verify.txt; then
    fail "$label failed: $url"
  fi

  echo "OK: $label"
}

check_contains() {
  local label="$1"
  local needle="$2"

  if ! grep -q "$needle" /tmp/aem-verify.txt; then
    fail "$label missing expected value: $needle"
  fi
}

check_http "${AUTHOR_URL}/system/console/bundles.json" "Author reachable"
check_http "${PUBLISH_URL}/system/console/bundles.json" "Publish reachable"

check_http "${AUTHOR_URL}/content/dam/store-platform.json" "DAM folder /content/dam/store-platform"
check_http "${AUTHOR_URL}/content/dam/store-platform/content-fragments.json" "DAM folder /content/dam/store-platform/content-fragments"

check_http "${AUTHOR_URL}${MODEL_ITEMS_PATH}" "Content Fragment Model HomePage"
check_contains "Model field" "\"name\":\"title\""
check_contains "Model field" "\"name\":\"heroTitle\""
check_contains "Model field" "\"name\":\"heroSubtitle\""

check_http "${AUTHOR_URL}${CONTENT_FRAGMENT_PATH}/jcr:content/data/master/elements.1.json" "Content Fragment instance home"
check_contains "Content Fragment value" "\"value\":\"Home\""
check_contains "Content Fragment value" "\"value\":\"Welcome to Store Platform\""
check_contains "Content Fragment value" "\"value\":\"Modern Next.js + AEM Headless\""

check_http "${PUBLISH_URL}${GRAPHQL_ENDPOINT_PATH}" "GraphQL endpoint store"

check_http "${PERSISTED_QUERY_URL}" "Persisted query homePageByPath"
check_contains "Persisted query response" "homePageByPath"

rm -f /tmp/aem-verify.txt

echo "All checks passed."
