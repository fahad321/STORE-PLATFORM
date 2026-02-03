import "dotenv/config";
import { z } from "zod";

const UrlOrUndefined = z.preprocess(
  (value) => (value === "" || value === undefined ? undefined : value),
  z.string().url().optional(),
);

const EnvSchema = z.object({
  PORT: z
    .string()
    .optional()
    .transform((value) => (value ? Number(value) : 4001))
    .refine((value) => Number.isFinite(value) && value > 0, {
      message: "PORT must be a positive number",
    }),
  HOST: z.string().optional().default("0.0.0.0"),
  CORS_ORIGIN: z.string().optional().default("http://localhost:3000"),
  PRODUCTS_API_URL: UrlOrUndefined,
  API_KEY: z.string().optional(),
  AEM_ENDPOINT: UrlOrUndefined,
  AEM_HERO_ENDPOINT: UrlOrUndefined,
  AEM_AUTH_HEADER: z.string().optional(),
  LOG_LEVEL: z.string().optional().default("info"),
});

export type ServiceEnv = z.infer<typeof EnvSchema>;

export function loadEnv(input: NodeJS.ProcessEnv = process.env): ServiceEnv {
  return EnvSchema.parse(input);
}
