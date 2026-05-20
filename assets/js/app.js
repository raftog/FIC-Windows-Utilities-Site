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

async function hydrateApp(appKey, prefix) {
  try {
    const {release, asset} = await loadRelease(appKey);
    setText(`${prefix}Version`, release.tag_name || release.name);
    setText(`${prefix}Downloads`, asset ? asset.download_count.toLocaleString() : t("not_available"));
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
    console.warn("Release load failed:", appKey, err);
  }
}

initLanguages();
hydrateApp("latencycheck", "latency");
hydrateApp("harddisktemp", "harddisk");
