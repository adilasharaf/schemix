import { z } from 'zod';

// ── Order (Type) ──
export interface Order {
  id: string;
  userId: string;
  status: string;
  orderNumber?: number | null;
  creditCardToken?: string | null;
}

// ── Order (Schema) ──
export const OrderSchema: z.ZodType<Order> = z.object({
  id: z.string(),
  userId: z.string(),
  status: z.string(),
  orderNumber: z.number().int().nullish(),
  creditCardToken: z.string().nullish(),
});