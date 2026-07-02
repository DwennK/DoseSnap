import { describe, expect, it } from "vitest";
import { foodAnalysisResponseSchema, normalizeFoodAnalysis } from "../src/schemas/foodAnalysis";

describe("foodAnalysisResponseSchema", () => {
  it("accepts the iOS response contract", () => {
    const parsed = foodAnalysisResponseSchema.parse({
      detected_items: [{ name: "Pizza", estimated_carbs_g: 110, confidence: 0.75 }],
      total_carbs_low_g: 90,
      total_carbs_mid_g: 110,
      total_carbs_high_g: 160,
      confidence: 0.75,
      warnings: ["A verifier."],
      explanation: "Pizza moyenne detectee."
    });

    expect(parsed.detected_items[0]?.name).toBe("Pizza");
  });

  it("normalizes carb range ordering", () => {
    const normalized = normalizeFoodAnalysis({
      detected_items: [{ name: "Pates", estimated_carbs_g: 72.4, confidence: 0.8 }],
      total_carbs_low_g: 80.2,
      total_carbs_mid_g: 70.1,
      total_carbs_high_g: 75.9,
      confidence: 0.8,
      warnings: [],
      explanation: "Bol de pates."
    });

    expect(normalized.total_carbs_low_g).toBe(80);
    expect(normalized.total_carbs_mid_g).toBe(80);
    expect(normalized.total_carbs_high_g).toBe(80);
    expect(normalized.detected_items[0]?.estimated_carbs_g).toBe(72);
  });
});
