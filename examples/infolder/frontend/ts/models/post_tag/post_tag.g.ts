import { z } from 'zod';
import { Post, PostSchema } from '../post/post.g';
import { Tag, TagSchema } from '../tag/tag.g';

// ── PostTag (Type) ──
export interface PostTag {
  id: string;
  postId: string;
  tagId: string;
  post?: Post | null;
  tag?: Tag | null;
}

// ── PostTag (Schema) ──
export const PostTagSchema: z.ZodType<PostTag> = z.lazy(() =>
  z.object({
    id: z.string(),
    postId: z.string(),
    tagId: z.string(),
    post: z.lazy(() => PostSchema).nullish(),
    tag: z.lazy(() => TagSchema).nullish(),
  })
) as unknown as z.ZodType<PostTag>;