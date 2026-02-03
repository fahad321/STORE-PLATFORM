# Content Service

Fastify service that exposes AEM content and products via HTTP.

## Run

```bash
pnpm --filter @services/content-service dev
```

## Auth (optional)

If `API_KEY` is set, requests must include:

```
X-API-Key: <your-key>
```

## Endpoints

- `GET /health`
- `GET /content/hero?revalidateSeconds=60&endpoint=...`
- `GET /content/home?path=/content/dam/...&revalidateSeconds=60&endpoint=...`
- `GET /content/products?revalidateSeconds=60&endpoint=...`

## Examples

```bash
curl http://localhost:4001/health
curl "http://localhost:4001/content/hero?revalidateSeconds=60"
curl "http://localhost:4001/content/home?path=/content/dam/site/home.json"
curl "http://localhost:4001/content/products?revalidateSeconds=60"
```
