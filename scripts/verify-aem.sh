#!/usr/bin/env bash
set -euo pipefail

AUTHOR_URL="${AEM_AUTHOR_URL:-http://localhost:4502}"
PUBLISH_URL="${AEM_PUBLISH_URL:-http://localhost:4503}"
GRAPHQL_ENDPOINT_PATH="${AEM_GRAPHQL_ENDPOINT_PATH:-/content/_cq_graphql/store/endpoint.json}"
PERSISTED_QUERY_URL="${AEM_PERSISTED_QUERY_URL:-$PUBLISH_URL/graphql/execute.json/store/homePageByPath}"
AUTH_HEADER="${AEM_AUTH_HEADER:-}"

curl_check() {
  local url="$1"
  local label="$2"

  if [[ -n "$AUTH_HEADER" ]]; then
    curl -fsS -H "Authorization: $AUTH_HEADER" "$url" > /dev/null
  else
    curl -fsS "$url" > /dev/null
  fi

  echo "OK: $label reachable at $url"
}

curl_check "$AUTHOR_URL" "AEM Author"
curl_check "$PUBLISH_URL" "AEM Publish"

curl_check "$PUBLISH_URL$GRAPHQL_ENDPOINT_PATH" "GraphQL endpoint"

curl_check "$PERSISTED_QUERY_URL" "Persisted query homePageByPath"
