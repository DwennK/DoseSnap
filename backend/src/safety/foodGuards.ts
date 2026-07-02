import type { FoodAnalysisResponse } from "../schemas/foodAnalysis";

const lowConfidenceThreshold = 0.55;

export function applyFoodAnalysisGuards(analysis: FoodAnalysisResponse): FoodAnalysisResponse {
  const warnings = [...analysis.warnings];

  if (analysis.detected_items.length === 0 || analysis.total_carbs_high_g <= 0) {
    warnings.push("Photo incertaine ou aliment non detecte. Estimez manuellement avant toute decision.");
  }

  if (analysis.confidence < lowConfidenceThreshold) {
    warnings.push("Confiance IA faible. Pesez ou estimez manuellement le repas.");
  }

  if (analysis.total_carbs_high_g > 150) {
    warnings.push("Glucides potentiellement eleves. Verifiez la portion et les ingredients.");
  }

  warnings.push("Estimation a verifier avec votre propre jugement et vos consignes medicales.");

  return {
    ...analysis,
    warnings: Array.from(new Set(warnings))
  };
}
