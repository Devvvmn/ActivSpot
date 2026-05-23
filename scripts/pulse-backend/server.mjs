#!/usr/bin/env node
import { createServer } from "node:http";

const PORT = 7334;
const HOST = "0.0.0.0"; // Allow external connections (e.g., from phone)

let currentPulse = {
  rate: "72",
  icon: "󰏤",
  timestamp: Date.now()
};

let history = [];
const MAX_HISTORY = 20;

function send(res, status, body) {
  res.writeHead(status, { 
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*" 
  });
  res.end(JSON.stringify(body));
}

async function readBody(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  return JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}");
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://${HOST}`);
  
  // CORS support
  if (req.method === "OPTIONS") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type"
    });
    return res.end();
  }

  if (url.pathname === "/pulse" && req.method === "GET") {
    return send(res, 200, { ...currentPulse, history });
  }

  if (url.pathname === "/pulse" && req.method === "POST") {
    try {
      const body = await readBody(req);

      let rate = null;

      // Check for Zepp/Health app structure: body.data.metrics[].data[].Avg
      if (body.data && Array.isArray(body.data.metrics)) {
        const hrMetric = body.data.metrics.find(m => m.name === "heart_rate" || (Array.isArray(m.data) && m.data.length > 0 && typeof m.data[0].Avg !== "undefined"));
        
        if (hrMetric && Array.isArray(hrMetric.data) && hrMetric.data.length > 0) {
          const lastPoint = hrMetric.data[hrMetric.data.length - 1];
          if (typeof lastPoint.Avg !== "undefined") {
            // Round to nearest integer (e.g. 93.00000001 -> 93)
            rate = String(Math.round(lastPoint.Avg));
          }
        }
      } 
      // Fallback to simple format: { "rate": 80 }
      else if (typeof body.rate !== "undefined") {
        rate = String(body.rate);
      }

      if (rate !== null) {
        currentPulse = {
          rate: rate,
          icon: body.icon || "󰏤",
          timestamp: Date.now()
        };

        console.log(`[pulse-backend] Updated Rate: ${rate} BPM`);

        // Add to history
        history.push({ rate: currentPulse.rate, time: currentPulse.timestamp });
        if (history.length > MAX_HISTORY) history.shift();

        // Trigger instant UI update via inotify
        import("node:child_process").then(cp => {
          cp.exec("touch /tmp/qs_pulse_update", () => {});
        });

        return send(res, 200, { ok: true, data: currentPulse });
      }

      console.log("[pulse-backend] Received unknown format:", JSON.stringify(body, null, 2));
      return send(res, 400, { error: "Unknown data format" });
    } catch (e) {
      console.error("[pulse-backend] Error parsing request:", e);
      return send(res, 400, { error: "Invalid JSON" });
    }
  }


  send(res, 404, { error: "Not found" });
});

server.listen(PORT, HOST, () => {
  console.log(`[pulse-backend] listening on http://${HOST}:${PORT}`);
});
