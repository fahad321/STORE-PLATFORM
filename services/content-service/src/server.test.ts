import { describe, expect, it, beforeEach, vi } from "vitest";
import { buildServer } from "./server.js";
import type { ServiceEnv } from "./env.js";

vi.mock("@packages/aem", () => ({
  getHeroBanner: vi.fn(async () => ({ title: "Hero", description: "Desc" })),
  getHomePage: vi.fn(async () => ({ title: "Home", heroTitle: "Hero", heroSubtitle: "Sub" })),
}));

describe("content-service", () => {
  let env: ServiceEnv;

  beforeEach(() => {
    env = {
      PORT: 4001,
      HOST: "0.0.0.0",
      CORS_ORIGIN: "http://localhost:3000",
      PRODUCTS_API_URL: "http://example.com/products",
      API_KEY: undefined,
      AEM_ENDPOINT: undefined,
      AEM_HERO_ENDPOINT: undefined,
      AEM_AUTH_HEADER: undefined,
      LOG_LEVEL: "info",
    };
  });

  it("returns health", async () => {
    const app = buildServer({ env });
    const res = await app.inject({ method: "GET", url: "/health" });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ ok: true });
  });

  it("requires API key when configured", async () => {
    const app = buildServer({ env: { ...env, API_KEY: "secret" } });
    const res = await app.inject({ method: "GET", url: "/content/hero" });
    expect(res.statusCode).toBe(401);
  });

  it("returns hero content", async () => {
    const app = buildServer({ env });
    const res = await app.inject({ method: "GET", url: "/content/hero" });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ title: "Hero", description: "Desc" });
  });

  it("validates home query", async () => {
    const app = buildServer({ env });
    const res = await app.inject({ method: "GET", url: "/content/home" });
    expect(res.statusCode).toBe(400);
  });

  it("returns products", async () => {
    const app = buildServer({ env });
    const products = [
      {
        id: "p1",
        name: "Product",
        price: 10,
        imageUrl: "https://example.com/image.png",
        description: "Desc",
        category: "Cat",
      },
    ];

    vi.stubGlobal("fetch", vi.fn(async () => ({
      ok: true,
      json: async () => products,
    })) as unknown as typeof fetch);

    const res = await app.inject({ method: "GET", url: "/content/products" });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual(products);

    vi.unstubAllGlobals();
  });
});
