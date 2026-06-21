import { z } from 'zod';
import { Post, PostSchema } from '../post/post.g';
import { Profile, ProfileSchema } from '../profile/profile.g';

// ── User (Type) ──
export interface User {
  id: string;
  email: string;
  passwordHash: string;
  displayName?: string | null;
  posts: Array<Post>;
  profile?: Profile | null;
  metadata?: Record<string, unknown> | null;
}

// ── User (Schema) ──
export const UserSchema: z.ZodType<User> = z.lazy(() =>
  z.object({
    id: z.string(),
    email: z.string().email().max(255),
    passwordHash: z.string(),
    displayName: z.string().max(100).nullish(),
    posts: z.array(z.lazy(() => PostSchema)),
    profile: z.lazy(() => ProfileSchema).nullish(),
    metadata: z.record(z.string(), z.unknown()).nullish(),
  })
) as unknown as z.ZodType<User>;