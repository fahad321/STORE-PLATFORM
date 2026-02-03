import { z } from "zod";

export const RevalidateSchema = z
  .string()
  .optional()
  .transform((value) => (value ? Number(value) : 60))
  .refine((value) => Number.isFinite(value) && value > 0, {
    message: "revalidateSeconds must be a positive number",
  });

export const HeroQuerySchema = z.object({
  revalidateSeconds: RevalidateSchema,
  endpoint: z.string().url().optional(),
});

export const HomeQuerySchema = z.object({
  path: z.string().min(1),
  revalidateSeconds: RevalidateSchema,
  endpoint: z.string().url().optional(),
});

export const ProductsQuerySchema = z.object({
  revalidateSeconds: RevalidateSchema,
  endpoint: z.string().url().optional(),
});

export const HealthResponseSchema = z.object({ ok: z.boolean() });
export const HeroResponseSchema = z.object({
  title: z.string(),
  description: z.string().optional(),
});
export const HomeResponseSchema = z.object({
  title: z.string(),
  heroTitle: z.string().optional(),
  heroSubtitle: z.string().optional(),
});
export const ProductSchema = z.object({
  id: z.string(),
  name: z.string(),
  price: z.number(),
  imageUrl: z.string().url().optional(),
  description: z.string().optional(),
  category: z.string().optional(),
});
export const ProductsResponseSchema = z.array(ProductSchema);

export type HealthResponse = z.infer<typeof HealthResponseSchema>;
export type HeroResponse = z.infer<typeof HeroResponseSchema>;
export type HomeResponse = z.infer<typeof HomeResponseSchema>;
export type ProductsResponse = z.infer<typeof ProductsResponseSchema>;
