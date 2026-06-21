import { z } from 'zod';

// ── Tag (Type) ──
export interface Tag {
  id: string;
  name: string;
  slug: string;
}

// ── Tag (Schema) ──
export const TagSchema: z.ZodType<Tag> = z.object({
  id: z.string(),
  name: z.string().min(1).max(50),
  slug: z.string(),
});