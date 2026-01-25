# AEM Setup Automation

This directory contains automation scripts for setting up and verifying AEM integration in the store-platform project.

## Quick Start

1. **Set up AEM SDK:**
   - Download AEM SDK from Adobe
   - Start Author instance: `java -jar aem-sdk-quickstart-author-*.jar`
   - Start Publish instance: `java -jar aem-sdk-quickstart-publish-*.jar`

2. **Install content package to Author:**
   ```bash
   ./install-author.sh
   ```

3. **Install content package to Publish:**
   ```bash
   ./install-publish.sh
   ```

4. **Create persisted query (via GraphiQL UI):**
   - Open: http://localhost:4502/aem/graphiql.html
   - Go to "Persisted Queries" tab
   - Create query: `store-platform/homePageByPath`
   - Use the GraphQL query from `aem/jcr_root/conf/store-platform/settings/graphql/persistentQueries/homePageByPath/.content.xml`

5. **Verify installation:**
   ```bash
   ./verify.sh
   ```

6. **Configure Next.js app:**
   ```bash
   cp env.example ../apps/web/.env.local
   # Edit .env.local with your AEM endpoint
   ```

7. **Start Next.js dev server:**
   ```bash
   cd ../../ && pnpm dev
   ```

## Scripts

### `install-author.sh`
Builds and installs the AEM content package to the local Author instance (default: localhost:4502).

### `install-publish.sh`
Builds and installs the AEM content package to the local Publish instance (default: localhost:4503).

### `verify.sh`
Verifies that:
- AEM instances are accessible
- DAM folder structure exists
- Content Fragment is created
- Content Fragment Model is configured
- GraphQL persisted query works
- Returns proper HTTP status codes

### `verify-aem.sh`
Verifies Next.js environment configuration and AEM connectivity from the app perspective.

### `install-package.sh`
Installs the AEM package and its dependencies. Run this when setting up a new environment or after pulling changes.

### `env.example`
Template for environment variables. Copy to `.env.local` in `apps/web/` and fill in your AEM instance details.

## AEM Content Package

The content package (located in `../../aem/`) includes:

- **DAM Folder**: `/content/dam/store-platform/content-fragments`
- **Content Fragment Model**: `HomePage` with fields: `title`, `heroTitle`, `heroSubtitle`
- **Sample Fragment**: `home` at `/content/dam/store-platform/content-fragments/home`
- **Persisted Query**: `homePageByPath` at `/content/cq:graphql/persistent-endpoint/store-platform/homePageByPath`

## Environment Variables

Required:
- `AEM_ENDPOINT`: Full URL to your AEM GraphQL endpoint (persisted query or GraphQL endpoint)
  - Local SDK Author: `http://localhost:4502/graphql/execute.json/store-platform/homePageByPath`
  - Local SDK Publish: `http://localhost:4503/graphql/execute.json/store-platform/homePageByPath`
  - AEMaaCS: `https://author-p[program-id]-e[env-id].adobeaemcloud.com/graphql/execute.json/store-platform/homePageByPath`

Optional:
- `AEM_MODE`: Either `PERSISTED_GET` (default) or `GRAPHQL_POST`
- `AEM_AUTH_HEADER`: Authorization header value (e.g., `Bearer <token>` or `Basic <credentials>`)

## GraphQL Endpoint

After installation, the persisted query will be available at:

**Local SDK Author:**
```
http://localhost:4502/graphql/execute.json/store-platform/homePageByPath?path=/content/dam/store-platform/content-fragments/home
```

**Local SDK Publish:**
```
http://localhost:4503/graphql/execute.json/store-platform/homePageByPath?path=/content/dam/store-platform/content-fragments/home
```

**AEMaaCS:**
```
https://author-p[program-id]-e[env-id].adobeaemcloud.com/graphql/execute.json/store-platform/homePageByPath?path=/content/dam/store-platform/content-fragments/home
```

## Troubleshooting

- **"Invalid URL" error**: Check that `AEM_ENDPOINT` is set and is a valid URL
- **Connection refused**: Verify your AEM instance is running and accessible
- **401/403 errors**: Check your `AEM_AUTH_HEADER` value
- **GraphQL errors**: Verify the persisted query exists or the GraphQL schema matches
- **Maven build fails**: Ensure Maven is installed and AEM SDK is running
- **Package installation fails**: Check AEM instance credentials (default: admin/admin)

## Maintenance

These scripts are maintained by the development team. If you encounter issues:
1. Check the script output for specific error messages
2. Verify your environment variables
3. Test AEM connectivity independently (curl, Postman, etc.)
4. Update scripts as needed for your AEM setup
