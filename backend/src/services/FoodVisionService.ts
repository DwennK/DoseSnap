import type { FoodAnalysisResponse } from "../schemas/foodAnalysis";
import type { DecodedImage } from "../utils/base64";

export type AnalyzeFoodInput = {
  image: DecodedImage;
  locale: string;
};

export interface FoodVisionService {
  analyzeFood(input: AnalyzeFoodInput): Promise<FoodAnalysisResponse>;
}
