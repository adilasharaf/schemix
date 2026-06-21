import { z } from 'zod';

// ── Product (Type) ──
export interface Product {
  id: string;
  name: string;
  price: number;
  stock: number;
  type: string;
}

// ── Product (Schema) ──
export const ProductSchema: z.ZodType<Product> = z.object({
  id: z.string(),
  name: z.string().max(150),
  price: z.number().gte(0.0),
  stock: z.number().int().gte(0).lte(10000),
  type: z.string().refine(v => ['physical', 'digital'].includes(v as never)),
});