import { z } from 'zod';

// ── Profile (Type) ──
export interface Profile {
  id: string;
  userId: string;
  website?: string | null;
  phoneNumber?: string | null;
  isActive: boolean;
  age?: number | null;
}

// ── Profile (Schema) ──
export const ProfileSchema: z.ZodType<Profile> = z.lazy(() =>
  z.object({
    id: z.string(),
    userId: z.string(),
    website: z.string().url().nullish(),
    phoneNumber: z.string().regex(/^\+?[1-9]\d{1,14}$/u).nullish(),
    isActive: z.boolean(),
    age: z.number().int().gte(18).nullish(),
  })
) as unknown as z.ZodType<Profile>;