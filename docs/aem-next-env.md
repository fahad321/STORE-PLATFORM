# Next.js AEM Environment (Local SDK)

Create `apps/web/.env.local` with the following values:

```bash
AEM_MODE=PERSISTED_GET
AEM_ENDPOINT=http://localhost:4503/graphql/execute.json/store/homePageByPath
# Hero banner persisted query endpoint (URL-encode spaces)
AEM_HERO_ENDPOINT=http://localhost:4502/graphql/execute.json/Store-Platform/Hero%20Banner
# Optional for secured instances
# AEM_AUTH_HEADER=Bearer <token>
```

Persisted query execution (Publish):

```
http://localhost:4503/graphql/execute.json/store/homePageByPath;path=/content/dam/store-platform/content-fragments/home
```
