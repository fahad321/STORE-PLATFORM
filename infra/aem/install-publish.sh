#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AEM_DIR="$REPO_ROOT/aem"

AEM_HOST="${AEM_PUBLISH_HOST:-localhost}"
AEM_PORT="${AEM_PUBLISH_PORT:-4503}"
AEM_USER="${AEM_PUBLISH_USER:-admin}"
AEM_PASSWORD="${AEM_PUBLISH_PASSWORD:-admin}"
AEM_URL="http://${AEM_HOST}:${AEM_PORT}"
PACKAGE_NAME="store-platform-content"

delete_legacy() {
  local path="$1"
  local url="${AEM_URL}${path}"
  local code
  code=$(curl -sS -o /tmp/aem-publish-delete.txt -w "%{http_code}" -u "${AEM_USER}:${AEM_PASSWORD}" -X POST -F ":operation=delete" "$url" || echo "000")
  if [[ "$code" == "404" ]]; then
    echo "OK: Legacy path not found (skip delete) $path"
    return 0
  fi
  if [[ "$code" != "200" && "$code" != "204" ]]; then
    echo "ERROR: Failed to delete legacy path $path (HTTP $code)" >&2
    cat /tmp/aem-publish-delete.txt >&2 || true
    exit 1
  fi
  echo "OK: Deleted legacy path $path"
}

build_package() {
  echo "Building AEM content package..."
  (cd "$AEM_DIR" && mvn -q clean package)
}

find_package() {
  local pkg
  pkg=$(ls "$AEM_DIR"/target/*.zip 2>/dev/null | head -n 1 || true)
  if [[ -z "$pkg" ]]; then
    echo "ERROR: Package zip not found in $AEM_DIR/target" >&2
    exit 1
  fi
  echo "$pkg"
}

install_package() {
  local pkg="$1"
  echo "Uploading package to Publish: $AEM_URL"
  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "file=@${pkg}" \
    -F "name=${PACKAGE_NAME}" \
    -F "force=true" \
    -F "install=true" \
    "${AEM_URL}/crx/packmgr/service.jsp" > /tmp/aem-publish-install.xml

  if ! grep -q "<status code=\"200\">" /tmp/aem-publish-install.xml; then
    echo "ERROR: Publish install failed. Response:" >&2
    cat /tmp/aem-publish-install.xml >&2
    exit 1
  fi

  echo "Publish install OK"
}

ensure_content_fragment() {
  local base="${AEM_URL}/content/dam/store-platform/content-fragments/home"

  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "jcr:primaryType=dam:AssetContent" \
    -F "jcr:mimeType=application/json" \
    -F "dam:status=draft" \
    -F "cq:model=/conf/store/settings/dam/cfm/models/homepage" \
    "${base}/jcr:content" > /dev/null

  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "jcr:primaryType=nt:unstructured" \
    "${base}/jcr:content/data" > /dev/null

  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "jcr:primaryType=nt:unstructured" \
    "${base}/jcr:content/data/master" > /dev/null

  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "jcr:primaryType=nt:unstructured" \
    "${base}/jcr:content/data/master/elements" > /dev/null

  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "jcr:primaryType=nt:unstructured" \
    -F "value=Home" \
    "${base}/jcr:content/data/master/elements/title" > /dev/null

  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "jcr:primaryType=nt:unstructured" \
    -F "value=Welcome to Store Platform" \
    "${base}/jcr:content/data/master/elements/heroTitle" > /dev/null

  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "jcr:primaryType=nt:unstructured" \
    -F "value=Modern Next.js + AEM Headless" \
    "${base}/jcr:content/data/master/elements/heroSubtitle" > /dev/null

  echo "Publish content fragment seeded"
}

ensure_persisted_query() {
  if [[ "${SKIP_PERSISTED_QUERY:-false}" == "1" || "${SKIP_PERSISTED_QUERY:-false}" == "true" ]]; then
    echo "Skipping persisted query creation (SKIP_PERSISTED_QUERY set)"
    return 0
  fi

  local url="${AEM_URL}/graphql/persist.json/store/homePageByPath"
  local payload='{"query":"query HomePageByPath($path: String!) { homePageByPath(_path: $path) { item { _path title { value } heroTitle { value } heroSubtitle { value } } } }"}'
  local code

  code=$(curl -sS -o /tmp/aem-publish-persist.txt -w "%{http_code}" \
    -u "${AEM_USER}:${AEM_PASSWORD}" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$url" || echo "000")

  if [[ "$code" == "409" ]]; then
    code=$(curl -sS -o /tmp/aem-publish-persist.txt -w "%{http_code}" \
      -u "${AEM_USER}:${AEM_PASSWORD}" \
      -X POST \
      -H "Content-Type: application/json" \
      -d "$payload" \
      "$url" || echo "000")
  fi

  if [[ "$code" != "200" && "$code" != "201" ]]; then
    echo "ERROR: Failed to persist query (HTTP $code)" >&2
    cat /tmp/aem-publish-persist.txt >&2 || true
    echo "" >&2
    echo "Manual fallback (SDK UI) required to persist the query:" >&2
    echo "1) Open http://localhost:4503/aem/graphiql.html" >&2
    echo "2) Create persisted query named store/homePageByPath" >&2
    echo "3) Query body:" >&2
    echo "   query HomePageByPath(\$path: String!) { homePageByPath(_path: \$path) { item { _path title { value } heroTitle { value } heroSubtitle { value } } } }" >&2
    exit 1
  fi

  echo "Publish persisted query ensured"
}

ensure_graphql_endpoint() {
  local endpoint="${AEM_URL}/content/_cq_graphql/store/endpoint/jcr:content"
  curl -fsS -u "${AEM_USER}:${AEM_PASSWORD}" \
    -F "jcr:primaryType=cq:PageContent" \
    -F "sling:resourceType=cq/graphql/endpoints/config" \
    -F "cq:allowedPaths=/content/dam/store-platform" \
    -F "enabled=true" \
    "$endpoint" > /dev/null
  echo "Publish GraphQL endpoint ensured"
}

build_package
PKG_PATH="$(find_package)"
delete_legacy "/content/cq%3Agraphql/persistent-endpoint/store-platform"
delete_legacy "/conf/store-platform"
delete_legacy "/content/cq%3Agraphql/persistent-endpoint/store/homePageByPath"
delete_legacy "/conf/store/settings/graphql/persistentQueries/homePageByPath"
install_package "$PKG_PATH"
ensure_content_fragment
ensure_graphql_endpoint
ensure_persisted_query

rm -f /tmp/aem-publish-install.xml /tmp/aem-publish-delete.txt /tmp/aem-publish-persist.txt
