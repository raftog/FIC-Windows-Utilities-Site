/**
 * F.I.C. Windows Utilities counters Worker.
 *
 * Routes:
 *   POST /api/visit
 *   GET  /api/stats
 *   GET  /download/latencycheck
 *   GET  /download/harddisktemp
 *
 * KV binding:
 *   DOWNLOAD_STATS
 *
 * Privacy:
 * - No IP address is stored.
 * - Only aggregate counters are stored.
 * - Country comes from Cloudflare request.cf.country.
 */

const DOWNLOADS = {
  latencycheck: "https://github.com/raftog/LatencyCheck-Updates/releases/latest/download/LatencyCheck_Setup_Professional_GUI.exe",
  harddisktemp: "https://github.com/raftog/HardDiskTemp-Updates/releases/latest/download/Build_HardDiskTemp_Install.exe"
};

const ALLOWED_ORIGINS = [
  "https://raftog.github.io",
  "https://apps.forensiclabs.gr",
  "https://www.forensiclabs.gr"
];

function corsHeaders(request) {
  const origin = request.headers.get("Origin") || "";
  const allowOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : "*";
  return {
    "access-control-allow-origin": allowOrigin,
    "access-control-allow-methods": "GET,POST,OPTIONS",
    "access-control-allow-headers": "content-type",
    "cache-control": "no-store"
  };
}

function json(request, data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      ...corsHeaders(request),
      "content-type": "application/json; charset=utf-8"
    }
  });
}

async function increment(env, key) {
  const oldValue = parseInt((await env.DOWNLOAD_STATS.get(key)) || "0", 10);
  const next = oldValue + 1;
  await env.DOWNLOAD_STATS.put(key, String(next));
  return next;
}

async function readInt(env, key) {
  return parseInt((await env.DOWNLOAD_STATS.get(key)) || "0", 10);
}

async function listCounters(env, prefix) {
  const out = [];
  let cursor = undefined;

  do {
    const list = await env.DOWNLOAD_STATS.list({ prefix, cursor });
    for (const k of list.keys) {
      const count = await readInt(env, k.name);
      const suffix = k.name.substring(prefix.length) || "XX";
      out.push({ country: suffix, count });
    }
    cursor = list.list_complete ? undefined : list.cursor;
  } while (cursor);

  out.sort((a, b) => b.count - a.count || a.country.localeCompare(b.country));
  return out.slice(0, 100);
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(request) });
    }

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";
    const country = (request.cf && request.cf.country) ? request.cf.country : "XX";

    if (path === "/api/visit" && request.method === "POST") {
      ctx.waitUntil(increment(env, "visits:total"));
      ctx.waitUntil(increment(env, `visits:country:${country}`));
      return json(request, { ok: true, counted: "visit" });
    }

    if (path === "/api/stats" && request.method === "GET") {
      const latencyTotal = await readInt(env, "download:latencycheck:total");
      const harddiskTotal = await readInt(env, "download:harddisktemp:total");

      return json(request, {
        visits: {
          total: await readInt(env, "visits:total"),
          byCountry: await listCounters(env, "visits:country:")
        },
        downloads: {
          total: latencyTotal + harddiskTotal,
          latencycheck: latencyTotal,
          harddisktemp: harddiskTotal,
          byCountry: {
            latencycheck: await listCounters(env, "download:latencycheck:country:"),
            harddisktemp: await listCounters(env, "download:harddisktemp:country:")
          }
        },
        privacy: "Aggregate counters only. No IP storage."
      });
    }

    if (path.startsWith("/download/")) {
      const app = path.split("/").filter(Boolean)[1];

      if (!DOWNLOADS[app]) {
        return json(request, { error: "Unknown application" }, 404);
      }

      ctx.waitUntil(increment(env, `download:${app}:total`));
      ctx.waitUntil(increment(env, `download:${app}:country:${country}`));

      return Response.redirect(DOWNLOADS[app], 302);
    }

    return json(request, {
      ok: true,
      service: "F.I.C. Windows Utilities counters Worker",
      routes: ["/api/visit", "/api/stats", "/download/latencycheck", "/download/harddisktemp"]
    });
  }
};
