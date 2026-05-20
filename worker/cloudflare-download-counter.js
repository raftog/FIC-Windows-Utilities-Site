/**
 * Cloudflare Worker for F.I.C. Windows Utilities counters.
 *
 * Routes:
 *   POST /api/visit
 *   GET  /api/stats
 *   GET  /download/latencycheck
 *   GET  /download/harddisktemp
 *
 * Bind a KV namespace named DOWNLOAD_STATS.
 *
 * Privacy:
 * - No IP address is stored.
 * - Only aggregate counters are stored.
 * - Country is read from Cloudflare request.cf.country.
 */

const DOWNLOADS = {
  latencycheck: "https://github.com/raftog/LatencyCheck-Updates/releases/latest/download/LatencyCheck_Setup_Professional_GUI.exe",
  harddisktemp: "https://github.com/raftog/HardDiskTemp-Updates/releases/latest/download/Build_HardDiskTemp_Install.exe"
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET,POST,OPTIONS",
      "access-control-allow-headers": "content-type"
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

async function listCountryCounters(env, prefix) {
  const out = [];
  const list = await env.DOWNLOAD_STATS.list({ prefix });
  for (const k of list.keys) {
    const count = await readInt(env, k.name);
    const country = k.name.substring(prefix.length) || "XX";
    out.push({ country, count });
  }
  out.sort((a, b) => b.count - a.count || a.country.localeCompare(b.country));
  return out.slice(0, 50);
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return json({ ok: true });
    }

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";
    const country = (request.cf && request.cf.country) ? request.cf.country : "XX";

    if (path === "/api/visit" && request.method === "POST") {
      ctx.waitUntil(increment(env, "visits:total"));
      ctx.waitUntil(increment(env, `visits:country:${country}`));
      return json({ ok: true });
    }

    if (path === "/api/stats" && request.method === "GET") {
      const visitsTotal = await readInt(env, "visits:total");

      const latencyTotal = await readInt(env, "download:latencycheck:total");
      const harddiskTotal = await readInt(env, "download:harddisktemp:total");

      const data = {
        visits: {
          total: visitsTotal,
          byCountry: await listCountryCounters(env, "visits:country:")
        },
        downloads: {
          total: latencyTotal + harddiskTotal,
          latencycheck: latencyTotal,
          harddisktemp: harddiskTotal,
          byCountry: {
            latencycheck: await listCountryCounters(env, "download:latencycheck:country:"),
            harddisktemp: await listCountryCounters(env, "download:harddisktemp:country:")
          }
        },
        privacy: "Aggregate counters only. No IP storage."
      };

      return json(data);
    }

    if (path.startsWith("/download/")) {
      const app = path.split("/").filter(Boolean)[1];
      if (!DOWNLOADS[app]) {
        return json({ error: "Unknown application" }, 404);
      }

      ctx.waitUntil(increment(env, `download:${app}:total`));
      ctx.waitUntil(increment(env, `download:${app}:country:${country}`));

      return Response.redirect(DOWNLOADS[app], 302);
    }

    return json({ error: "Not found" }, 404);
  }
};
