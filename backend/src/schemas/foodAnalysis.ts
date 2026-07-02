import { z } from "zod";

export const detectedFoodItemSchema = z.object({
  name: z.string().trim().min(1).max(120),
  estimated_carbs_g: z.number().finite().min(0).max(500),
  confidence: z.number().finite().min(0).max(1)
});

export const foodAnalysisResponseSchema = z.object({
  detected_items: z.array(detectedFoodItemSchema).max(20),
  total_carbs_low_g: z.number().finite().min(0).max(500),
  total_carbs_mid_g: z.number().finite().min(0).max(500),
  total_carbs_high_g: z.number().finite().min(0).max(500),
  confidence: z.number().finite().min(0).max(1),
  warnings: z.array(z.string().trim().min(1).max(240)).max(12).default([]),
  explanation: z.string().trim().min(1).max(800)
});

export type DetectedFoodItem = z.infer<typeof detectedFoodItemSchema>;
export type FoodAnalysisResponse = z.infer<typeof foodAnalysisResponseSchema>;

export function normalizeFoodAnalysis(input: FoodAnalysisResponse): FoodAnalysisResponse {
  const low = Math.max(0, Math.round(input.total_carbs_low_g));
  const mid = Math.max(low, Math.round(input.total_carbs_mid_g));
  const high = Math.max(mid, Math.round(input.total_carbs_high_g));

  return {
    detected_items: input.detected_items.map((item) => ({
      name: item.name.trim(),
      estimated_carbs_g: Math.max(0, Math.round(item.estimated_carbs_g)),
      confidence: clamp01(item.confidence)
    })),
    total_carbs_low_g: low,
    total_carbs_mid_g: mid,
    total_carbs_high_g: high,
    confidence: clamp01(input.confidence),
    warnings: uniqueWarnings(input.warnings),
    explanation: input.explanation.trim()
  };
}

export function makeUncertainAnalysis(warnings: string[], explanation: string): FoodAnalysisResponse {
  return {
    detected_items: [],
    total_carbs_low_g: 0,
    total_carbs_mid_g: 0,
    total_carbs_high_g: 0,
    confidence: 0,
    warnings: uniqueWarnings(warnings),
    explanation
  };
}

function clamp01(value: number): number {
  return Math.min(1, Math.max(0, value));
}

function uniqueWarnings(warnings: string[]): string[] {
  return Array.from(new Set(warnings.map((warning) => warning.trim()).filter(Boolean)));
}
