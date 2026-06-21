import { z } from 'zod';
import { Tag, TagSchema } from '../tag/tag.g';

// ── PostStatus (Enum) ──
export const PostStatusSchema = z.enum(['draft', 'published', 'archived']);
export type PostStatus = z.infer<typeof PostStatusSchema>;

// ── Post (Type) ──
export interface Post {
  id: string;
  title?: string | null;
  body?: string | null;
  slug?: string | null;
  status: PostStatus;
  userId?: string | null;
  categoryId?: string | null;
  tags: Array<Tag>;
}

// ── Post (Schema) ──
export const PostSchema: z.ZodType<Post> = z.lazy(() =>
  z.object({
    id: z.string(),
    title: z.string().min(1).max(255).nullish(),
    body: z.string().nullish(),
    slug: z.string().nullish(),
    status: PostStatusSchema.catch('draft'),
    userId: z.string().nullish(),
    categoryId: z.string().nullish(),
    tags: z.array(TagSchema),
  })
) as unknown as z.ZodType<Post>;