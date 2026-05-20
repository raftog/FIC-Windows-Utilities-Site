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
  if (!text) return t("not_available");
  return text
    .replace(/```[\s\S]*?```/g, "")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/\*([^*]+)\*/g, "$1")
    .replace(/^#+\s*/gm, "")
    .trim();
}

function setReleaseNotes(prefix, release) {
  setText(`${prefix}ReleaseTitle`, release.name || release.tag_name || t("not_available"));
  const el = document.getElementById(`${prefix}ReleaseNotes`);
  if (el) {
    const body = stripMarkdown(release.body || "");
    el.textContent = body || t("not_available");
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
      // On GitHub Pages there is no /download route.
      // Use the exact release asset URL when GitHub API returns it; otherwise use the stable latest/download fallback.
      btn.href = (asset && asset.browser_download_url) ? asset.browser_download_url : CONFIG.redirects[appKey];
      btn.dataset.directGithubUrl = btn.href;
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
    await fetch("/api/visit", {method: "POST", cache: "no-store"});
  } catch (_) {}

  try {
    const res = await fetch("/api/stats", {cache: "no-store"});
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
