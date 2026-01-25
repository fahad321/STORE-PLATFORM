import { z } from "zod";

/**
 * AEM Client - Day 2 baseline
 * WHY: keep AEM access behind a typed adapter so the app stays scalable.
 */

const UrlOrUndefined = z.preprocess(
  (value) => (value === "" || value === undefined ? undefined : value),
  z.string().url().optional(),
);

const EnvSchema = z.object({
  AEM_MODE: z.enum(["PERSISTED_GET", "GRAPHQL_POST"]).default("PERSISTED_GET"),
  AEM_ENDPOINT: UrlOrUndefined,
  AEM_HERO_ENDPOINT: UrlOrUndefined,
  // Optional: for Author or protected Publish
  AEM_AUTH_HEADER: z.string().optional(),
});

type Env = z.infer<typeof EnvSchema>;

function env(): Env {
  return EnvSchema.parse({
    AEM_MODE: process.env.AEM_MODE,
    AEM_ENDPOINT: process.env.AEM_ENDPOINT,
    AEM_HERO_ENDPOINT: process.env.AEM_HERO_ENDPOINT,
    AEM_AUTH_HEADER: process.env.AEM_AUTH_HEADER,
  });
}

async function aemFetch<T>(url: string, init?: RequestInit): Promise<T> {
  const { AEM_AUTH_HEADER } = env();
  const headers: Record<string, string> = {
    ...(init?.headers as Record<string, string> | undefined),
    ...(AEM_AUTH_HEADER ? { Authorization: AEM_AUTH_HEADER } : {}),
  };

  const res = await fetch(url, { ...init, headers });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`AEM request failed: ${res.status} ${res.statusText} ${text}`);
  }
  return (await res.json()) as T;
}

/**
 * Update this schema to match YOUR content fragment model.
 * Start minimal for Day 2, expand later.
 */
const HomeSchema = z.object({
  data: z.object({
    homePageByPath: z.object({
      item: z.object({
        title: z.string(),
        heroTitle: z.string().optional(),
        heroSubtitle: z.string().optional(),
      }),
    }),
  }),
});

export type HomeContent = {
  title: string;
  heroTitle?: string;
  heroSubtitle?: string;
};

const HeroBannerSchema = z.object({
  data: z.object({
    homepageByPath: z.object({
      item: z.object({
        title: z.string(),
        description: z.string().optional(),
      }),
    }),
  }),
});

export type HeroBannerContent = {
  title: string;
  description?: string;
};

/**
 * Fetch home page content fragment by path.
 * - Persisted query is preferred
 * - POST is supported as fallback
 */
export async function getHomePage(input: {
  path: string;
  revalidateSeconds?: number;
}): Promise<HomeContent> {
  const { AEM_MODE, AEM_ENDPOINT } = env();
  const revalidateSeconds = input.revalidateSeconds ?? 60;

  if (!AEM_ENDPOINT) {
    throw new Error("Missing AEM_ENDPOINT for home page query");
  }

  if (AEM_MODE === "PERSISTED_GET") {
    const url = new URL(AEM_ENDPOINT);
    url.searchParams.set("path", input.path);

    const json = await aemFetch<unknown>(url.toString(), {
      method: "GET",
      // Next.js caching hint for server components
      next: { revalidate: revalidateSeconds },
    } as any);

    const parsed = HomeSchema.parse(json);
    const item = parsed.data.homePageByPath.item;
    return { title: item.title, heroTitle: item.heroTitle, heroSubtitle: item.heroSubtitle };
  }

  // GRAPHQL_POST
  const query = `
    query HomePageByPath($path: String!) {
      homePageByPath(_path: $path) {
        item {
          title
          heroTitle
          heroSubtitle
        }
      }
    }
  `;

  const json = await aemFetch<unknown>(AEM_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables: { path: input.path } }),
    next: { revalidate: revalidateSeconds },
  } as any);

  const parsed = HomeSchema.parse(json);
  const item = parsed.data.homePageByPath.item;
  return { title: item.title, heroTitle: item.heroTitle, heroSubtitle: item.heroSubtitle };
}

/**
 * Fetch hero banner content via persisted query endpoint.
 * Uses AEM_HERO_ENDPOINT to keep endpoints centralized and explicit.
 */
export async function getHeroBanner(input?: {
  revalidateSeconds?: number;
  endpoint?: string;
}): Promise<HeroBannerContent> {
  const { AEM_HERO_ENDPOINT } = env();
  const revalidateSeconds = input?.revalidateSeconds ?? 60;
  const endpoint = input?.endpoint ?? AEM_HERO_ENDPOINT;

  if (!endpoint) {
    throw new Error("Missing AEM_HERO_ENDPOINT for hero banner query");
  }

  const json = await aemFetch<unknown>(endpoint, {
    method: "GET",
    next: { revalidate: revalidateSeconds },
  } as any);

  const parsed = HeroBannerSchema.parse(json);
  const item = parsed.data.homepageByPath.item;
  return { title: item.title, description: item.description };
}
