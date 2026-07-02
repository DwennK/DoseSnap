import type { Env } from "../types/env";

export type AppConfig = {
  minimaxApiKey: string;
  minimaxBaseUrl: string;
  minimaxModel: string;
  appApiToken: string | undefined;
  maxImageBytes: number;
  requireDeviceIntegrity: boolean;
  useMockVision: boolean;
};

const defaultMaxImageBytes = 5 * 1024 * 1024;

export function getConfig(env: Env = {}): AppConfig {
  const maxImageBytes = parsePositiveInt(env.MAX_IMAGE_BYTES, defaultMaxImageBytes);

  return {
    minimaxApiKey: env.MINIMAX_API_KEY ?? "",
    minimaxBaseUrl: trimTrailingSlash(env.MINIMAX_BASE_URL ?? "https://api.minimax.io/v1"),
    minimaxModel: env.MINIMAX_MODEL ?? "MiniMax-M3",
    appApiToken: env.APP_API_TOKEN,
    maxImageBytes,
    requireDeviceIntegrity: env.REQUIRE_DEVICE_INTEGRITY === "true",
    useMockVision: env.USE_MOCK_VISION === "true"
  };
}

function parsePositiveInt(value: string | undefined, fallback: number): number {
  if (!value) {
    return fallback;
  }

  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, "");
}
