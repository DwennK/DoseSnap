import { describe, expect, it } from "vitest";
import { applyFoodAnalysisGuards } from "../src/safety/foodGuards";
import type { FoodAnalysisResponse } from "../src/schemas/foodAnalysis";

const baseAnalysis: FoodAnalysisResponse = {
  detected_items: [{ name: "Snickers standard", estimated_carbs_g: 33, confidence: 0.86 }],
  total_carbs_low_g: 30,
  total_carbs_mid_g: 33,
  total_carbs_high_g: 38,
  confidence: 0.86,
  warnings: [],
  explanation: "Barre chocolatee standard detectee."
};

describe("applyFoodAnalysisGuards", () => {
  it("always adds a cautious verification warning", () => {
    const guarded = applyFoodAnalysisGuards(baseAnalysis);

    expect(guarded.warnings).toContain("Estimation a verifier avec votre propre jugement et vos consignes medicales.");
  });

  it("warns on low confidence", () => {
    const guarded = applyFoodAnalysisGuards({ ...baseAnalysis, confidence: 0.3 });

    expect(guarded.warnings).toContain("Confiance IA faible. Pesez ou estimez manuellement le repas.");
  });

  it("warns when no food is detected", () => {
    const guarded = applyFoodAnalysisGuards({
      ...baseAnalysis,
      detected_items: [],
      total_carbs_low_g: 0,
      total_carbs_mid_g: 0,
      total_carbs_high_g: 0,
      confidence: 0
    });

    expect(guarded.warnings).toContain("Photo incertaine ou aliment non detecte. Estimez manuellement avant toute decision.");
  });
});
