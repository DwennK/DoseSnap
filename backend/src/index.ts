import { Hono } from "hono";
import { cors } from "hono/cors";
import { secureHeaders } from "hono/secure-headers";
import { analyzeFoodRoute } from "./routes/analyzeFood";
import { healthRoute } from "./routes/health";
import type { FoodVisionService } from "./services/FoodVisionService";
import type { Env } from "./types/env";

type Variables = {
  foodVisionService?: FoodVisionService;
};

export function createApp(foodVisionService?: FoodVisionService) {
  const app = new Hono<{ Bindings: Env; Variables: Variables }>();

  app.use("*", secureHeaders());
  app.use(
    "*",
    cors({
      origin: "*",
      allowMethods: ["GET", "POST", "OPTIONS"],
      allowHeaders: ["Authorization", "Content-Type"]
    })
  );

  if (foodVisionService) {
    app.use("*", async (context, next) => {
      context.set("foodVisionService", foodVisionService);
      await next();
    });
  }

  app.route("/", healthRoute);
  app.route("/", analyzeFoodRoute);

  app.notFound((context) => context.json({ error: "not_found" }, 404));

  app.onError((error, context) => {
    console.error("Unhandled worker error", error);
    return context.json({ error: "internal_error" }, 500);
  });

  return app;
}

export default createApp();
