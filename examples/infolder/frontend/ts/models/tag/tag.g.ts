import { z } from 'zod';
import { PostTag, PostTagSchema } from '../post_tag/post_tag.g';

// ── Tag (Type) ──
export interface Tag {
  id: string;
  name: string;
  slug: string;
  posts: Array<PostTag>;
}

// ── Tag (Schema) ──
export const TagSchema: z.ZodType<Tag> = z.lazy(() =>
  z.object({
    id: z.string(),
    name: z.string().min(1).max(50),
    slug: z.string(),
    posts: z.array(z.lazy(() => PostTagSchema)).default([]),
  })
) as unknown as z.ZodType<Tag>;