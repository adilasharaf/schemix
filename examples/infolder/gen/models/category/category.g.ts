import { z } from 'zod';
import { Post, PostSchema } from '../post/post.g';

// ── CategoryType (Enum) ──
export const CategoryTypeSchema = z.enum(['standard', 'premium', 'internal']);
export type CategoryType = z.infer<typeof CategoryTypeSchema>;

// ── Category (Type) ──
export interface Category {
  id: string;
  name: string;
  type: CategoryType;
  posts: Array<Post>;
}

// ── Category (Schema) ──
export const CategorySchema: z.ZodType<Category> = z.lazy(() =>
  z.object({
    id: z.string(),
    name: z.string().min(3).max(100),
    type: CategoryTypeSchema.catch('standard'),
    posts: z.array(z.lazy(() => PostSchema)),
  })
) as unknown as z.ZodType<Category>;