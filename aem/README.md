# AEM Content Package

This directory contains the AEM Maven project for deploying content to AEMaaCS SDK.

## Structure

- `jcr_root/` - Content package structure
  - `content/dam/store-platform/` - DAM folder structure
  - `conf/store-platform/` - Configuration (Content Fragment Models)
  - `content/cq:graphql/persistent-endpoint/` - Persisted GraphQL queries
- `pom.xml` - Maven project configuration
- `META-INF/` - Package metadata

## What This Package Creates

1. **DAM Folder Structure**
   - `/content/dam/store-platform/content-fragments`

2. **Content Fragment Model**
   - Model: `HomePage`
   - Location: `/conf/store-platform/settings/dam/cfm/models/homepage`
   - Fields:
     - `title` (required, text-single)
     - `heroTitle` (optional, text-single)
     - `heroSubtitle` (optional, text-multi)

3. **Sample Content Fragment**
   - Name: `home`
   - Location: `/content/dam/store-platform/content-fragments/home`
   - Model: `HomePage`

4. **Persisted GraphQL Query**
   - Name: `homePageByPath`
   - Endpoint: `/content/cq:graphql/persistent-endpoint/store-platform/homePageByPath`
   - Query: Fetches home page content by path

## Building the Package

```bash
cd aem
mvn clean package
```

This creates `store-platform-content-1.0.0-SNAPSHOT.zip` in the `target/` directory.

## Installation

Use the provided scripts:
- `../infra/aem-setup/install-author.sh` - Install to Author instance
- `../infra/aem-setup/install-publish.sh` - Install to Publish instance

Or manually:
```bash
mvn clean package -PautoInstallPackage
```

## GraphQL Endpoint URLs

After installation, the persisted query will be available at:

**Author:**
```
http://localhost:4502/graphql/execute.json/store-platform/homePageByPath?path=/content/dam/store-platform/content-fragments/home
```

**Publish:**
```
http://localhost:4503/graphql/execute.json/store-platform/homePageByPath?path=/content/dam/store-platform/content-fragments/home
```

**AEMaaCS (Cloud Service):**
```
https://author-p[program-id]-e[env-id].adobeaemcloud.com/graphql/execute.json/store-platform/homePageByPath?path=/content/dam/store-platform/content-fragments/home
```

