import { describe, expect, it } from "vitest";
import { createApp } from "../src";
import type { FoodAnalysisResponse } from "../src/schemas/foodAnalysis";
import type { AnalyzeFoodInput, FoodVisionService } from "../src/services/FoodVisionService";
import { foodImageFixtures } from "./fixtures/images";

class MockFoodVisionService implements FoodVisionService {
  lastInput: AnalyzeFoodInput | undefined;

  async analyzeFood(input: AnalyzeFoodInput): Promise<FoodAnalysisResponse> {
    this.lastInput = input;

    return {
      detected_items: [{ name: "Snickers standard", estimated_carbs_g: 33, confidence: 0.86 }],
      total_carbs_low_g: 30,
      total_carbs_mid_g: 33,
      total_carbs_high_g: 38,
      confidence: 0.86,
      warnings: [],
      explanation: "Barre chocolatee standard detectee."
    };
  }
}

describe("POST /analyze-food", () => {
  it("returns the iOS food analysis contract", async () => {
    const service = new MockFoodVisionService();
    const app = createApp(service);

    const response = await app.request("/analyze-food", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        image_base64: btoa("fake-image"),
        locale: "fr-FR"
      })
    });

    expect(response.status).toBe(200);
    const json = await response.json<FoodAnalysisResponse>();
    expect(json.detected_items[0]?.name).toBe("Snickers standard");
    expect(json.total_carbs_mid_g).toBe(33);
    expect(json.warnings).toContain("Estimation a verifier avec votre propre jugement et vos consignes medicales.");
    expect(service.lastInput?.locale).toBe("fr-FR");
  });

  it("rejects oversized images before calling the model", async () => {
    const service = new MockFoodVisionService();
    const app = createApp(service);

    const response = await app.request(
      "/analyze-food",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          image_base64: btoa("too-large")
        })
      },
      {
        MAX_IMAGE_BYTES: "2"
      }
    );

    expect(response.status).toBe(413);
    expect(service.lastInput).toBeUndefined();
  });

  it("rejects real model mode when backend auth is not configured", async () => {
    const app = createApp();

    const response = await app.request("/analyze-food", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        image_base64: btoa("fake-image")
      })
    });

    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ error: "backend_auth_not_configured" });
  });

  it.each(foodImageFixtures)("returns valid JSON for $name fixture", async (fixture) => {
    const app = createApp(new MockFoodVisionService());

    const response = await app.request("/analyze-food", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        image_base64: fixture.imageBase64,
        locale: "fr-FR"
      })
    });

    expect(response.status).toBe(200);
    const json = await response.json<FoodAnalysisResponse>();
    expect(json).toMatchObject({
      total_carbs_mid_g: expect.any(Number),
      confidence: expect.any(Number),
      warnings: expect.any(Array),
      explanation: expect.any(String)
    });
  });

  it("returns an uncertain analysis when the model response is unusable", async () => {
    const app = createApp(new ThrowingFoodVisionService());

    const response = await app.request("/analyze-food", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        image_base64: btoa("fake-image")
      })
    });

    expect(response.status).toBe(200);
    const json = await response.json<FoodAnalysisResponse>();
    expect(json.detected_items).toEqual([]);
    expect(json.confidence).toBe(0);
    expect(json.warnings).toContain("Analyse IA indisponible. Estimez manuellement les glucides avant de sauvegarder.");
  });

  it("fails closed when device integrity verification is enabled but not implemented", async () => {
    const app = createApp(new MockFoodVisionService());

    const response = await app.request(
      "/analyze-food",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ image_base64: btoa("fake-image") })
      },
      {
        REQUIRE_DEVICE_INTEGRITY: "true"
      }
    );

    expect(response.status).toBe(501);
    expect(await response.json()).toEqual({ error: "device_integrity_verification_not_implemented" });
  });

  it("applies Cloudflare rate limiting by device key when binding is configured", async () => {
    const app = createApp(new MockFoodVisionService());

    const response = await app.request(
      "/analyze-food",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-DoseSnap-Device-ID": "test-device"
        },
        body: JSON.stringify({ image_base64: btoa("fake-image") })
      },
      {
        ANALYZE_RATE_LIMITER: {
          async limit({ key }: { key: string }) {
            expect(key).toBe("analyze-food:test-device");
            return { success: false };
          }
        }
      }
    );

    expect(response.status).toBe(429);
    expect(await response.json()).toEqual({ error: "rate_limited" });
  });
});

class ThrowingFoodVisionService implements FoodVisionService {
  async analyzeFood(): Promise<FoodAnalysisResponse> {
    throw new Error("minimax_non_json_response");
  }
}
