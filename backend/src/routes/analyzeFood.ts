import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { getConfig } from "../config/env";
import { analyzeFoodRequestSchema } from "../schemas/request";
import { applyFoodAnalysisGuards } from "../safety/foodGuards";
import { makeUncertainAnalysis, type FoodAnalysisResponse } from "../schemas/foodAnalysis";
import { MiniMaxFoodVisionService } from "../services/MiniMaxFoodVisionService";
import { MockFoodVisionService } from "../services/MockFoodVisionService";
import type { FoodVisionService } from "../services/FoodVisionService";
import type { Env } from "../types/env";
import { decodeImageBase64 } from "../utils/base64";
import { elapsedMs, logEvent } from "../utils/logger";

type Variables = {
  foodVisionService?: FoodVisionService;
};

export const analyzeFoodRoute = new Hono<{ Bindings: Env; Variables: Variables }>();

analyzeFoodRoute.post(
  "/analyze-food",
  zValidator("json", analyzeFoodRequestSchema, (result, context) => {
    if (!result.success) {
      return context.json({ error: "invalid_request" }, 400);
    }
  }),
  async (context) => {
    const requestId = crypto.randomUUID();
    const requestStart = performance.now();
    const env = context.env ?? {};
    const config = getConfig(env);
    const injectedFoodVisionService = context.get("foodVisionService");
    const deviceId = context.req.header("X-DoseSnap-Device-ID") ?? "";
    const integrityHeaders = {
      appAttestKeyId: context.req.header("X-DoseSnap-App-Attest-Key-ID"),
      appAttestAssertion: context.req.header("X-DoseSnap-App-Attest-Assertion"),
      deviceCheckToken: context.req.header("X-DoseSnap-DeviceCheck-Token")
    };
    const rateLimitKey = context.req.header("cf-connecting-ip") || deviceId || "unknown-device";

    if (env.ANALYZE_RATE_LIMITER) {
      const { success } = await env.ANALYZE_RATE_LIMITER.limit({ key: `analyze-food:${rateLimitKey}` });
      if (!success) {
        logEvent("warn", "analyze_food_rate_limited", {
          request_id: requestId,
          status: 429,
          has_device_id: Boolean(deviceId),
          total_duration_ms: elapsedMs(requestStart)
        });
        return context.json({ error: "rate_limited" }, 429);
      }
    }

    if (config.requireDeviceIntegrity) {
      logEvent("warn", "analyze_food_integrity_not_implemented", {
        request_id: requestId,
        status: 501,
        has_device_id: Boolean(deviceId),
        total_duration_ms: elapsedMs(requestStart)
      });
      return context.json({ error: "device_integrity_verification_not_implemented" }, 501);
    }

    if (!config.useMockVision && !config.appApiToken && !injectedFoodVisionService) {
      logEvent("error", "analyze_food_auth_not_configured", {
        request_id: requestId,
        status: 503
      });
      return context.json({ error: "backend_auth_not_configured" }, 503);
    }

    if (config.appApiToken) {
      const authorization = context.req.header("Authorization");
      if (authorization !== `Bearer ${config.appApiToken}`) {
        logEvent("warn", "analyze_food_unauthorized", {
          request_id: requestId,
          status: 401
        });
        return context.json({ error: "unauthorized" }, 401);
      }
    }

    const payload = context.req.valid("json");
    let imageBytes = 0;
    let modelDurationMs: number | undefined;

    try {
      const image = decodeImageBase64(payload.image_base64, config.maxImageBytes);
      imageBytes = image.bytes.byteLength;
      const service = injectedFoodVisionService ?? makeFoodVisionService(config);
      const modelStart = performance.now();
      let analysis: FoodAnalysisResponse;
      try {
        analysis = await service.analyzeFood({ image, locale: payload.locale });
      } finally {
        modelDurationMs = elapsedMs(modelStart);
      }
      const guardedAnalysis = applyFoodAnalysisGuards(analysis);

      logEvent("info", "analyze_food_completed", {
        request_id: requestId,
        status: 200,
        has_device_id: Boolean(deviceId),
        has_integrity_proof: hasAnyIntegrityProof(integrityHeaders),
        image_bytes: imageBytes,
        model_duration_ms: modelDurationMs,
        total_duration_ms: elapsedMs(requestStart),
        confidence: guardedAnalysis.confidence,
        detected_item_count: guardedAnalysis.detected_items.length
      });

      return context.json(guardedAnalysis);
    } catch (error) {
      const message = error instanceof Error ? error.message : "unknown_error";

      if (message === "image_too_large") {
        logEvent("warn", "analyze_food_rejected", {
          request_id: requestId,
          status: 413,
          error_code: message,
          total_duration_ms: elapsedMs(requestStart)
        });
        return context.json({ error: "image_too_large" }, 413);
      }

      if (message === "unsupported_image_type" || message === "empty_image") {
        logEvent("warn", "analyze_food_rejected", {
          request_id: requestId,
          status: 400,
          error_code: message,
          total_duration_ms: elapsedMs(requestStart)
        });
        return context.json({ error: message }, 400);
      }

      const fallback = applyFoodAnalysisGuards(
        makeUncertainAnalysis(
          ["Analyse IA indisponible. Estimez manuellement les glucides avant de sauvegarder."],
          "L'analyse automatique n'a pas pu produire une estimation fiable."
        )
      );

      logEvent("error", "analyze_food_fallback", {
        request_id: requestId,
        status: 200,
        has_device_id: Boolean(deviceId),
        has_integrity_proof: hasAnyIntegrityProof(integrityHeaders),
        image_bytes: imageBytes,
        model_duration_ms: modelDurationMs,
        error_code: message,
        total_duration_ms: elapsedMs(requestStart),
        confidence: fallback.confidence
      });

      return context.json(fallback);
    }
  }
);

function makeFoodVisionService(config: ReturnType<typeof getConfig>): FoodVisionService {
  if (config.useMockVision) {
    return new MockFoodVisionService();
  }

  return new MiniMaxFoodVisionService(config);
}

function hasAnyIntegrityProof(headers: {
  appAttestKeyId: string | undefined;
  appAttestAssertion: string | undefined;
  deviceCheckToken: string | undefined;
}): boolean {
  return Boolean(
    (headers.appAttestKeyId && headers.appAttestAssertion) ||
    headers.deviceCheckToken
  );
}
