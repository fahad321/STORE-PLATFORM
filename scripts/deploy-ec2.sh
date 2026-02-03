#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-/home/ubuntu/STORE-PLATFORM}"

cd "$REPO_DIR"

echo "==> Pull latest code"
git pull

echo "==> Install deps"
pnpm install

echo "==> Build shared packages"
pnpm --filter @packages/aem build

echo "==> Build services"
pnpm --filter @services/content-service build
pnpm --filter web build

echo "==> Restart processes"
pm2 restart content-service --update-env
pm2 restart web --update-env

pm2 save

echo "==> Done"
