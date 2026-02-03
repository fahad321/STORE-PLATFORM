import fastify, { FastifyInstance } from "fastify";
import type { FastifyReply } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import etag from "@fastify/etag";
import { randomUUID } from "crypto";
import { getHeroBanner, getHomePage } from "@packages/aem";
import type { ServiceEnv } from "./env.js";
import {
  HealthResponseSchema,
  HeroQuerySchema,
  HeroResponseSchema,
  HomeQuerySchema,
  HomeResponseSchema,
  ProductsQuerySchema,
  ProductsResponseSchema,
  type HealthResponse,
  type HeroResponse,
  type HomeResponse,
  type ProductsResponse,
} from "./schemas.js";

const JSON_CONTENT_TYPE = "application/json";

type QueryRecord = Record<string, unknown>;

type ServerOptions = {
  env: ServiceEnv;
};

export function buildServer({ env }: ServerOptions): FastifyInstance {
  const app = fastify({
    logger: {
      level: env.LOG_LEVEL,
    },
    genReqId: (req) => {
      const existing = req.headers["x-request-id"];
      if (typeof existing === "string" && existing.length > 0) {
        return existing;
      }
      return randomUUID();
    },
  });

  app.addHook("onRequest", (request, reply, done) => {
    reply.header("x-request-id", request.id);

    if (env.API_KEY) {
      const apiKey = request.headers["x-api-key"];
      if (apiKey !== env.API_KEY) {
        reply.code(401).send({ error: "Unauthorized", message: "Invalid API key" });
        return;
      }
    }

    done();
  });

  app.register(helmet);
  app.register(cors, {
    origin: env.CORS_ORIGIN,
  });
  app.register(rateLimit, {
    max: 100,
    timeWindow: "1 minute",
  });
  app.register(etag);

  function setCacheHeaders(reply: FastifyReply, seconds: number) {
    reply.header(
      "Cache-Control",
      `s-maxage=${seconds}, stale-while-revalidate=${seconds}`,
    );
    reply.header("Content-Type", JSON_CONTENT_TYPE);
  }

  app.get("/health", async (_request, reply) => {
    const response: HealthResponse = { ok: true };
    reply.send(HealthResponseSchema.parse(response));
  });

  app.get("/content/hero", async (request, reply) => {
    const parsed = HeroQuerySchema.safeParse(request.query as QueryRecord);
    if (!parsed.success) {
      reply.code(400).send({ error: "BadRequest", message: parsed.error.message });
      return;
    }

    const { revalidateSeconds, endpoint } = parsed.data;
    const data = await getHeroBanner({
      revalidateSeconds,
      endpoint,
    });

    const response: HeroResponse = HeroResponseSchema.parse(data);
    setCacheHeaders(reply, revalidateSeconds);
    reply.send(response);
  });

  app.get("/content/home", async (request, reply) => {
    const parsed = HomeQuerySchema.safeParse(request.query as QueryRecord);
    if (!parsed.success) {
      reply.code(400).send({ error: "BadRequest", message: parsed.error.message });
      return;
    }

    const { path, revalidateSeconds, endpoint } = parsed.data;
    const data = await getHomePage({
      path,
      revalidateSeconds,
      endpoint,
    });

    const response: HomeResponse = HomeResponseSchema.parse(data);
    setCacheHeaders(reply, revalidateSeconds);
    reply.send(response);
  });

  app.get("/content/products", async (request, reply) => {
    const parsed = ProductsQuerySchema.safeParse(request.query as QueryRecord);
    if (!parsed.success) {
      reply.code(400).send({ error: "BadRequest", message: parsed.error.message });
      return;
    }

    const { revalidateSeconds, endpoint } = parsed.data;
    const url = endpoint ?? env.PRODUCTS_API_URL;

    if (!url) {
      reply
        .code(500)
        .send({ error: "InternalServerError", message: "Missing PRODUCTS_API_URL" });
      return;
    }

    const res = await fetch(url, { method: "GET" });
    if (!res.ok) {
      const text = await res.text().catch(() => "");
      reply
        .code(500)
        .send({
          error: "UpstreamError",
          message: `${res.status} ${res.statusText} ${text}`,
        });
      return;
    }

    const data = (await res.json()) as unknown;
    const response: ProductsResponse = ProductsResponseSchema.parse(data);
    setCacheHeaders(reply, revalidateSeconds);
    reply.send(response);
  });

  app.setErrorHandler((error, _request, reply) => {
    app.log.error(error);
    reply.code(500).send({
      error: "InternalServerError",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  });

  return app;
}
