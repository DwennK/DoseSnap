import type { AppConfig } from "../config/env";
import { foodAnalysisResponseSchema, normalizeFoodAnalysis, type FoodAnalysisResponse } from "../schemas/foodAnalysis";
import type { AnalyzeFoodInput, FoodVisionService } from "./FoodVisionService";
import { toDataUrl } from "../utils/base64";

type MiniMaxChatResponse = {
  choices?: Array<{
    message?: {
      content?: string;
    };
  }>;
};

export class MiniMaxFoodVisionService implements FoodVisionService {
  constructor(private readonly config: AppConfig) {}

  async analyzeFood(input: AnalyzeFoodInput): Promise<FoodAnalysisResponse> {
    if (!this.config.minimaxApiKey) {
      throw new Error("minimax_api_key_missing");
    }

    const response = await fetch(`${this.config.minimaxBaseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${this.config.minimaxApiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: this.config.minimaxModel,
        temperature: 0.1,
        max_completion_tokens: 900,
        thinking: { type: "disabled" },
        messages: [
          {
            role: "system",
            content: buildSystemPrompt(input.locale)
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "Analyse cette image de repas ou aliment. Reponds uniquement avec le JSON demande."
              },
              {
                type: "image_url",
                image_url: {
                  url: toDataUrl(input.image),
                  detail: "default",
                  max_long_side_pixel: 1280
                }
              }
            ]
          }
        ]
      })
    });

    if (!response.ok) {
      const errorCode = await readMiniMaxErrorCode(response);
      const suffix = errorCode ? `_${errorCode}` : "";
      throw new Error(`minimax_request_failed_${response.status}${suffix}`);
    }

    const body = await response.json<MiniMaxChatResponse>();
    const content = body.choices?.[0]?.message?.content;

    if (!content) {
      throw new Error("minimax_empty_response");
    }

    const parsed = parseJsonContent(content);
    const analysis = foodAnalysisResponseSchema.parse(parsed);
    return normalizeFoodAnalysis(analysis);
  }
}

function buildSystemPrompt(locale: string): string {
  return [
    "Tu es un analyseur alimentaire pour une app de suivi personnel.",
    "Retourne une estimation prudente des glucides, jamais une instruction medicale.",
    `Langue des champs textuels: ${locale}.`,
    "Reponds uniquement en JSON valide avec ce schema exact:",
    "{",
    '  "detected_items": [{"name": "string", "estimated_carbs_g": 0, "confidence": 0.0}],',
    '  "total_carbs_low_g": 0,',
    '  "total_carbs_mid_g": 0,',
    '  "total_carbs_high_g": 0,',
    '  "confidence": 0.0,',
    '  "warnings": ["string"],',
    '  "explanation": "string"',
    "}",
    "Si l'image est incertaine, n'invente pas: mets une confiance basse et un warning.",
    "N'inclus aucune dose d'insuline, aucune consigne d'injection, aucune certitude medicale."
  ].join("\n");
}

function parseJsonContent(content: string): unknown {
  const trimmed = content.trim();

  if (trimmed.startsWith("{")) {
    return JSON.parse(trimmed);
  }

  const match = /\{[\s\S]*\}/.exec(trimmed);
  if (!match) {
    throw new Error("minimax_non_json_response");
  }

  return JSON.parse(match[0]);
}

async function readMiniMaxErrorCode(response: Response): Promise<string | undefined> {
  let text = "";

  try {
    text = await response.text();
  } catch {
    return undefined;
  }

  if (!text) {
    return undefined;
  }

  try {
    const parsed = JSON.parse(text) as {
      base_resp?: { status_code?: number | string };
      error?: { code?: number | string };
      code?: number | string;
    };
    const code = parsed.base_resp?.status_code ?? parsed.error?.code ?? parsed.code;
    return code === undefined ? undefined : String(code);
  } catch {
    return "unparseable_error_body";
  }
}
