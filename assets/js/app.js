const CONFIG = {
  repos: {
    latencycheck: "raftog/LatencyCheck-Updates",
    harddisktemp: "raftog/HardDiskTemp-Updates"
  },
  assets: {
    latencycheck: "LatencyCheck_Setup_Professional_GUI.exe",
    harddisktemp: "Build_HardDiskTemp_Install.exe"
  },
  redirects: {
    // GitHub Pages has no /download worker route.
    // For the public test site, download buttons must go directly to GitHub Releases.
    latencycheck: "https://github.com/raftog/LatencyCheck-Updates/releases/latest/download/LatencyCheck_Setup_Professional_GUI.exe",
    harddisktemp: "https://github.com/raftog/HardDiskTemp-Updates/releases/latest/download/Build_HardDiskTemp_Install.exe"
  }
};


function getWorkerBase() {
  const base = (window.FIC_COUNTER_WORKER_BASE || "").trim();
  return base.replace(/\/+$/, "");
}

function workerUrl(path) {
  const base = getWorkerBase();
  if (!base) return path;
  return `${base}${path.startsWith("/") ? path : "/" + path}`;
}

function isWorkerEnabled() {
  return !!getWorkerBase();
}


function t(key) {
  const lang = localStorage.getItem("fic_lang") || "el";
  return (window.FIC_TRANSLATIONS[lang] && window.FIC_TRANSLATIONS[lang][key]) ||
         (window.FIC_TRANSLATIONS.en && window.FIC_TRANSLATIONS.en[key]) ||
         key;
}

function applyLanguage(lang) {
  const info = window.FIC_LANGUAGES.find(x => x.code === lang) || window.FIC_LANGUAGES.find(x => x.code === "el");
  localStorage.setItem("fic_lang", info.code);
  document.documentElement.lang = info.code;
  document.documentElement.dir = info.dir || "ltr";
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.getAttribute("data-i18n");
    el.textContent = t(key);
  });
}

function initLanguages() {
  const select = document.getElementById("languageSelect");
  window.FIC_LANGUAGES.forEach(l => {
    const opt = document.createElement("option");
    opt.value = l.code;
    opt.textContent = `${l.native} / ${l.english}`;
    select.appendChild(opt);
  });
  const saved = localStorage.getItem("fic_lang") || "el";
  select.value = saved;
  applyLanguage(saved);
  select.addEventListener("change", e => applyLanguage(e.target.value));
}

async function loadRelease(appKey) {
  const repo = CONFIG.repos[appKey];
  const assetName = CONFIG.assets[appKey];
  const url = `https://api.github.com/repos/${repo}/releases/latest`;
  const res = await fetch(url, {headers: {"Accept":"application/vnd.github+json"}});
  if (!res.ok) throw new Error(`GitHub API ${res.status}`);
  const release = await res.json();
  const asset = (release.assets || []).find(a => a.name === assetName) || (release.assets || [])[0];
  return {release, asset};
}

function setText(id, value) {
  const el = document.getElementById(id);
  if (el) el.textContent = value || t("not_available");
}

function stripMarkdown(text) {
  if (!text) return "";
  return text
    .replace(/```[\s\S]*?```/g, "")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/\*([^*]+)\*/g, "$1")
    .replace(/^#+\s*/gm, "")
    .replace(/^\s*[-*]\s+/gm, "• ")
    .trim();
}

function buildOwnChangelog(prefix, release) {
  const version = release.tag_name || release.name || "";
  if (prefix === "latency") {
    return [
      `${t("current_version_label")}: ${version}`,
      "",
      `• ${t("latency_changelog_own_1")}`,
      `• ${t("latency_changelog_own_2")}`,
      `• ${t("latency_changelog_own_3")}`,
      `• ${t("latency_changelog_own_4")}`
    ].join("\n");
  }

  if (prefix === "harddisk") {
    return [
      `${t("current_version_label")}: ${version}`,
      "",
      `• ${t("harddisk_changelog_own_1")}`,
      `• ${t("harddisk_changelog_own_2")}`,
      `• ${t("harddisk_changelog_own_3")}`,
      `• ${t("harddisk_changelog_own_4")}`
    ].join("\n");
  }

  return stripMarkdown(release.body || "") || t("not_available");
}

function setReleaseNotes(prefix, release) {
  setText(`${prefix}ReleaseTitle`, release.name || release.tag_name || t("not_available"));
  const el = document.getElementById(`${prefix}ReleaseNotes`);
  if (el) {
    el.textContent = buildOwnChangelog(prefix, release);
  }
}



async function hydrateApp(appKey, prefix) {
  try {
    const {release, asset} = await loadRelease(appKey);
    setText(`${prefix}Version`, release.tag_name || release.name);
    setText(`${prefix}Downloads`, asset ? asset.download_count.toLocaleString() : t("not_available"));
    if (prefix === "latency") {
      SITE_COUNTERS.downloads.latency = asset ? asset.download_count : 0;
      setText("latencyStatsDownloads", asset ? asset.download_count.toLocaleString() : t("not_available"));
      setText("latencyStatsVersion", release.tag_name || release.name || t("not_available"));
    }
    if (prefix === "harddisk") {
      SITE_COUNTERS.downloads.harddisk = asset ? asset.download_count : 0;
      setText("harddiskStatsDownloads", asset ? asset.download_count.toLocaleString() : t("not_available"));
      setText("harddiskStatsVersion", release.tag_name || release.name || t("not_available"));
    }
    updateTotalDownloadCounter();
    setText(`${prefix}Sha`, asset && asset.digest ? asset.digest : t("not_available"));
    const btn = document.getElementById(`${prefix}Download`);
    if (btn) {
      // If Cloudflare Worker is configured, route downloads through it for counters.
      // Otherwise, GitHub Pages test mode uses direct GitHub Releases downloads.
      const directUrl = (asset && asset.browser_download_url) ? asset.browser_download_url : CONFIG.redirects[appKey];
      btn.dataset.directGithubUrl = directUrl;
      btn.href = isWorkerEnabled() ? workerUrl(`/download/${appKey}`) : directUrl;
    }
  } catch (err) {
    setText(`${prefix}Version`, t("not_available"));
    setText(`${prefix}Downloads`, t("not_available"));
    setText(`${prefix}Sha`, t("not_available"));
    if (prefix === "latency") {
      SITE_COUNTERS.downloads.latency = 0;
      setText("latencyStatsDownloads", t("not_available"));
      setText("latencyStatsVersion", t("not_available"));
    }
    if (prefix === "harddisk") {
      SITE_COUNTERS.downloads.harddisk = 0;
      setText("harddiskStatsDownloads", t("not_available"));
      setText("harddiskStatsVersion", t("not_available"));
    }
    updateTotalDownloadCounter();
    setText(`${prefix}ReleaseTitle`, t("not_available"));
    const relNotes = document.getElementById(`${prefix}ReleaseNotes`);
    if (relNotes) relNotes.textContent = t("not_available");
    console.warn("Release load failed:", appKey, err);
  }
}


const SITE_COUNTERS = {
  downloads: {
    latency: null,
    harddisk: null
  },
  worker: null
};

function formatCount(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return t("not_available");
  return n.toLocaleString();
}

function updateTotalDownloadCounter() {
  const a = Number(SITE_COUNTERS.downloads.latency || 0);
  const b = Number(SITE_COUNTERS.downloads.harddisk || 0);
  const hasAny = SITE_COUNTERS.downloads.latency !== null || SITE_COUNTERS.downloads.harddisk !== null;
  setText("totalStatsDownloads", hasAny ? formatCount(a + b) : t("not_available"));
}

function setCounterTable(rows) {
  const box = document.getElementById("countryStatsTable");
  if (!box) return;

  if (!rows || !rows.length) {
    box.textContent = t("counter_worker_pending");
    return;
  }

  const htmlRows = rows.map(r => {
    const app = r.app || "";
    const country = r.country || "XX";
    const count = formatCount(r.count || 0);
    return `<tr><td>${escapeHtml(app)}</td><td>${escapeHtml(country)}</td><td>${escapeHtml(count)}</td></tr>`;
  }).join("");

  box.innerHTML = `<table>
    <thead><tr><th>${escapeHtml(t("app"))}</th><th>${escapeHtml(t("country"))}</th><th>${escapeHtml(t("download_count"))}</th></tr></thead>
    <tbody>${htmlRows}</tbody>
  </table>`;
}

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

async function registerVisitAndLoadCounters() {
  // These endpoints exist only when the optional Cloudflare Worker is deployed.
  // On GitHub Pages they fail silently; GitHub release download counters still work.
  try {
    if (isWorkerEnabled()) await fetch(workerUrl("/api/visit"), {method: "POST", cache: "no-store"});
  } catch (_) {}

  try {
    if (!isWorkerEnabled()) throw new Error("worker disabled");
    const res = await fetch(workerUrl("/api/stats"), {cache: "no-store"});
    if (!res.ok) throw new Error(`stats ${res.status}`);
    const stats = await res.json();
    SITE_COUNTERS.worker = stats;

    if (stats.visits && typeof stats.visits.total !== "undefined") {
      setText("totalVisitsCounter", formatCount(stats.visits.total));
    }

    const rows = [];
    if (stats.downloads && stats.downloads.byCountry) {
      for (const appName of Object.keys(stats.downloads.byCountry)) {
        for (const row of stats.downloads.byCountry[appName] || []) {
          rows.push({app: appName, country: row.country, count: row.count});
        }
      }
    }
    setCounterTable(rows);
  } catch (_) {
    setText("totalVisitsCounter", t("counter_worker_pending"));
    setCounterTable([]);
  }
}


initLanguages();
hydrateApp("latencycheck", "latency");
hydrateApp("harddisktemp", "harddisk");
registerVisitAndLoadCounters();



/* v31 Worker statistics fix:
   Worker active with zero downloads should show "no downloads yet", not "Enabled with Worker".
   Also show visits by country and downloads by app/country. */
function ficV31EscapeHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function ficV31FormatCount(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return t("not_available");
  return n.toLocaleString();
}

function ficV31SetCountryStats(stats) {
  const box = document.getElementById("countryStatsTable");
  if (!box) return;

  const rows = [];

  const visits = stats && stats.visits && Array.isArray(stats.visits.byCountry)
    ? stats.visits.byCountry
    : [];

  for (const r of visits) {
    rows.push({
      type: t("visitor_counter"),
      country: r.country || "XX",
      count: r.count || 0
    });
  }

  const byCountry = stats && stats.downloads && stats.downloads.byCountry
    ? stats.downloads.byCountry
    : {};

  for (const r of (byCountry.latencycheck || [])) {
    rows.push({
      type: "LatencyCheck",
      country: r.country || "XX",
      count: r.count || 0
    });
  }

  for (const r of (byCountry.harddisktemp || [])) {
    rows.push({
      type: "HardDiskTemp",
      country: r.country || "XX",
      count: r.count || 0
    });
  }

  if (!isWorkerEnabled()) {
    box.textContent = t("counter_worker_pending");
    return;
  }

  if (!rows.length) {
    box.innerHTML = `<div class="counter-empty">${ficV31EscapeHtml(t("worker_active_no_country_data"))}</div>`;
    return;
  }

  rows.sort((a, b) => Number(b.count) - Number(a.count) || String(a.country).localeCompare(String(b.country)));

  const htmlRows = rows.map(r => {
    return `<tr><td>${ficV31EscapeHtml(r.type)}</td><td>${ficV31EscapeHtml(r.country)}</td><td>${ficV31EscapeHtml(ficV31FormatCount(r.count))}</td></tr>`;
  }).join("");

  box.innerHTML = `<table>
    <thead><tr><th>${ficV31EscapeHtml(t("counter_type"))}</th><th>${ficV31EscapeHtml(t("country"))}</th><th>${ficV31EscapeHtml(t("download_count"))}</th></tr></thead>
    <tbody>${htmlRows}</tbody>
  </table>`;
}

async function registerVisitAndLoadCounters() {
  try {
    if (!isWorkerEnabled()) throw new Error("worker disabled");

    await fetch(workerUrl("/api/visit"), { method: "POST", cache: "no-store" });

    const res = await fetch(workerUrl("/api/stats"), { cache: "no-store" });
    if (!res.ok) throw new Error(`stats ${res.status}`);

    const stats = await res.json();

    if (stats.visits && typeof stats.visits.total !== "undefined") {
      setText("totalVisitsCounter", ficV31FormatCount(stats.visits.total));
    } else {
      setText("totalVisitsCounter", t("not_available"));
    }

    if (stats.downloads) {
      if (typeof stats.downloads.total !== "undefined") setText("totalStatsDownloads", ficV31FormatCount(stats.downloads.total));
      if (typeof stats.downloads.latencycheck !== "undefined") setText("latencyStatsDownloads", ficV31FormatCount(stats.downloads.latencycheck));
      if (typeof stats.downloads.harddisktemp !== "undefined") setText("harddiskStatsDownloads", ficV31FormatCount(stats.downloads.harddisktemp));
    }

    ficV31SetCountryStats(stats);
  } catch (_) {
    setText("totalVisitsCounter", isWorkerEnabled() ? t("not_available") : t("counter_worker_pending"));
    const box = document.getElementById("countryStatsTable");
    if (box) box.textContent = isWorkerEnabled() ? t("worker_active_no_country_data") : t("counter_worker_pending");
  }
}

