/**
 * Cloudflare Worker for counted downloads by app and country.
 *
 * Routes:
 *   /download/latencycheck
 *   /download/harddisktemp
 *   /api/stats
 *
 * Bind a KV namespace named DOWNLOAD_STATS.
 * It stores aggregate counters only:
 *   total:latencycheck
 *   country:latencycheck:GR
 *
 * No IP address is stored.
 */

const DOWNLOADS = {
  latencycheck: "https://github.com/raftog/LatencyCheck-Updates/releases/latest/download/LatencyCheck_Setup_Professional_GUI.exe",
  harddisktemp: "https://github.com/raftog/HardDiskTemp-Updates/releases/latest/download/Build_HardDiskTemp_Install.exe"
};

async function increment(key) {
  const oldValue = parseInt((await DOWNLOAD_STATS.get(key)) || "0", 10);
  await DOWNLOAD_STATS.put(key, String(oldValue + 1));
  return oldValue + 1;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const parts = url.pathname.split("/").filter(Boolean);

    if (parts[0] === "download" && parts[1] && DOWNLOADS[parts[1]]) {
      const app = parts[1];
      const country = (request.cf && request.cf.country) ? request.cf.country : "XX";

      ctx.waitUntil(increment(`total:${app}`));
      ctx.waitUntil(increment(`country:${app}:${country}`));

      return Response.redirect(DOWNLOADS[app], 302);
    }

    if (url.pathname === "/api/stats") {
      return new Response(JSON.stringify({
        note: "Implement KV list aggregation or D1 for public dashboard.",
        privacy: "Aggregate counters only. No IP storage."
      }, null, 2), {
        headers: {"content-type": "application/json; charset=utf-8"}
      });
    }

    return new Response("Not found", {status: 404});
  }
};
