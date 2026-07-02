import type { FoodAnalysisResponse } from "../schemas/foodAnalysis";
import type { AnalyzeFoodInput, FoodVisionService } from "./FoodVisionService";

export class MockFoodVisionService implements FoodVisionService {
  async analyzeFood(input: AnalyzeFoodInput): Promise<FoodAnalysisResponse> {
    const preset = pickPreset(input.image.bytes.byteLength);

    return {
      ...preset,
      warnings: [
        ...preset.warnings,
        "Mode test local: estimation mock, sans analyse IA reelle."
      ]
    };
  }
}

const presets: FoodAnalysisResponse[] = [
  {
    detected_items: [{ name: "Snickers standard", estimated_carbs_g: 33, confidence: 0.86 }],
    total_carbs_low_g: 30,
    total_carbs_mid_g: 33,
    total_carbs_high_g: 38,
    confidence: 0.86,
    warnings: [],
    explanation: "Barre chocolatee standard detectee en mode mock."
  },
  {
    detected_items: [{ name: "Pizza moyenne", estimated_carbs_g: 120, confidence: 0.72 }],
    total_carbs_low_g: 90,
    total_carbs_mid_g: 120,
    total_carbs_high_g: 160,
    confidence: 0.72,
    warnings: ["Portion et pate a verifier manuellement."],
    explanation: "Pizza moyenne estimee en mode mock."
  },
  {
    detected_items: [{ name: "Salade composee", estimated_carbs_g: 24, confidence: 0.48 }],
    total_carbs_low_g: 10,
    total_carbs_mid_g: 24,
    total_carbs_high_g: 55,
    confidence: 0.48,
    warnings: ["Sauce, pain ou accompagnement non visibles: pesez ou estimez manuellement."],
    explanation: "Salade estimee avec incertitude en mode mock."
  }
];

function pickPreset(imageBytes: number): FoodAnalysisResponse {
  return presets[imageBytes % presets.length] ?? presets[0]!;
}
