import { buildServer } from "./server";
import { loadEnv } from "./env";

const env = loadEnv();
const app = buildServer({ env });

app
  .listen({ port: env.PORT, host: env.HOST })
  .then(() => {
    app.log.info(`content-service listening on http://${env.HOST}:${env.PORT}`);
  })
  .catch((err: unknown) => {
    app.log.error(err);
    process.exit(1);
  });
