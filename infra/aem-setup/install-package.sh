#!/bin/bash

# AEM Package Installation Script
# Installs the AEM package and its dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "📦 Installing AEM package and dependencies..."
echo ""

cd "$REPO_ROOT"

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}⚠️  pnpm not found. Installing...${NC}"
    npm install -g pnpm
fi

# Install dependencies
echo "🔧 Installing workspace dependencies..."
pnpm install

# Verify AEM package exists
if [ ! -d "$REPO_ROOT/packages/aem" ]; then
    echo -e "${YELLOW}⚠️  Warning: packages/aem directory not found${NC}"
    exit 1
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Copy infra/aem-setup/env.example to apps/web/.env.local"
echo "  2. Configure your AEM endpoint in apps/web/.env.local"
echo "  3. Run ./infra/aem-setup/verify-aem.sh to verify setup"
echo "  4. Run 'pnpm dev' to start the development server"

