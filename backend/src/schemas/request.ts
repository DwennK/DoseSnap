import { z } from "zod";

export const analyzeFoodRequestSchema = z.object({
  image_base64: z.string().min(1),
  locale: z.string().min(2).max(12).optional().default("fr-FR")
});

export type AnalyzeFoodRequest = z.infer<typeof analyzeFoodRequestSchema>;
