import { Hono } from "hono";
import type { Env } from "../types/env";

export const healthRoute = new Hono<{ Bindings: Env }>();

healthRoute.get("/health", (context) => {
  return context.json({
    ok: true,
    service: "dosesnap-api"
  });
});
