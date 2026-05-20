# F.I.C. Windows Utilities Site

Static software portal for:

- Latency Check Professional GUI
- HardDiskTemp

Suggested public address:

- `https://apps.forensiclabs.gr/`

Main site backlink:

- `https://www.forensiclabs.gr/`

## Contents

```text
index.html
assets/css/styles.css
assets/js/app.js
assets/js/translations.js
worker/cloudflare-download-counter.js
config/site-config.json
```

## Language support

The site includes the same 31 language selector structure requested for LatencyCheck.

Supported languages:

- Shqip / Albanian (`sq`)
- العربية / Arabic (`ar`)
- Български / Bulgarian (`bg`)
- 中文 / Chinese (`zh`)
- Hrvatski / Croatian (`hr`)
- Čeština / Czech (`cs`)
- Dansk / Danish (`da`)
- Nederlands / Dutch (`nl`)
- English / English (`en`)
- Suomi / Finnish (`fi`)
- Français / French (`fr`)
- Deutsch / German (`de`)
- Ελληνικά / Greek (`el`)
- עברית / Hebrew (`he`)
- हिन्दी / Hindi (`hi`)
- Magyar / Hungarian (`hu`)
- Italiano / Italian (`it`)
- 日本語 / Japanese (`ja`)
- 한국어 / Korean (`ko`)
- Norsk / Norwegian (`no`)
- Polski / Polish (`pl`)
- Português / Portuguese (`pt`)
- Română / Romanian (`ro`)
- Русский / Russian (`ru`)
- Српски / Serbian (`sr`)
- Slovenčina / Slovak (`sk`)
- Slovenščina / Slovenian (`sl`)
- Español / Spanish (`es`)
- Svenska / Swedish (`sv`)
- Türkçe / Turkish (`tr`)
- Українська / Ukrainian (`uk`)

Arabic and Hebrew switch the page to RTL.

## Downloads

The static page reads latest release metadata from:

- `raftog/LatencyCheck-Updates`
- `raftog/HardDiskTemp-Updates`

The visible Download buttons point to:

- `/download/latencycheck`
- `/download/harddisktemp`

Those routes are intended for the optional Cloudflare Worker so downloads can be counted by app and country before redirecting to GitHub Releases.

If you do not deploy the Worker yet, change the button links in `assets/js/app.js` to the direct GitHub latest-download URLs.

## Visitor counter

Use Cloudflare Web Analytics or another privacy-friendly analytics counter.
Do not store IP addresses for the download country counter. Store only aggregate counts.

## Deployment option A: upload to existing hosting

Upload the contents of this folder to a new subdomain or folder:

```text
apps.forensiclabs.gr
```

or

```text
www.forensiclabs.gr/software/
```

## Deployment option B: GitHub Pages

Create a repository, for example:

```text
FIC-Windows-Utilities-Site
```

Upload these files and enable GitHub Pages from the repository settings.

## Cloudflare Worker

The Worker file is optional but needed for:

- download counter per app
- download counter per country

Deploy `worker/cloudflare-download-counter.js` and bind a KV namespace named:

```text
DOWNLOAD_STATS
```

Generated: 2026-05-19T20:21:28


## v2 changes

- Electric-blue underlined styling for normal links.
- Expanded translations for all 31 languages across the site UI and main content keys.
- English fallback remains in JavaScript only as a safety net.

Generated v2: 2026-05-19T20:37:55


## v3 changes

- Added ready snippets for placing an electric-blue, underlined Apps link inside the existing main site:
  - `forensiclabs-main-site-link/ADD_APPS_LINK_TO_FORENSICLABS_GR.html`
  - `forensiclabs-main-site-link/MENU_ITEM_APPS_LINK.html`
  - `forensiclabs-main-site-link/FOOTER_APPS_LINK.html`
- Target link:
  - `https://apps.forensiclabs.gr/`
- This creates the reciprocal link:
  - `www.forensiclabs.gr` → `apps.forensiclabs.gr`
  - `apps.forensiclabs.gr` → `www.forensiclabs.gr`

Generated v3: 2026-05-19T23:57:54


## v4 changes

- Added direct link snippets from the existing `https://www.forensiclabs.gr/` site to the Apps statistics section.
- Exact requested target:
  - `FIC_Windows_Utilities_Site/index.html#statistics`
- Absolute alternative:
  - `https://apps.forensiclabs.gr/#statistics`
- Suggested placement:
  - left column `Επισκέπτες` box or the main site navigation menu.
- Normal link styling remains electric blue and underlined.

Generated v4: 2026-05-20T00:04:46
