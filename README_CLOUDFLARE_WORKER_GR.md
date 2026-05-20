# Cloudflare Worker ενεργοποίηση — F.I.C. Windows Utilities

Αυτό το πακέτο περιέχει έτοιμο Worker για:

- μετρητή επισκέψεων
- μετρητή λήψεων ανά εφαρμογή
- μετρητή λήψεων ανά χώρα
- αποθήκευση μόνο συγκεντρωτικών αριθμών, χωρίς IP

## Εκτέλεση

Από τον φάκελο `FIC-Windows-Utilities-Site` τρέχεις:

```text
20_DEPLOY_CLOUDFLARE_WORKER.cmd
```

Το script θα κάνει:

1. έλεγχο Node.js / npm,
2. εγκατάσταση Node.js LTS με winget αν λείπει,
3. Cloudflare login με Wrangler,
4. δημιουργία KV namespace `DOWNLOAD_STATS`,
5. deploy του Worker `fic-windows-utilities-counters`,
6. ενημέρωση του `assets/js/worker-config.js` με το Worker URL,
7. push της ενημερωμένης σελίδας στο GitHub Pages.

## Μετά

Άνοιξε:

```text
https://raftog.github.io/FIC-Windows-Utilities-Site/#statistics
```

Τα downloads θα περνάνε πλέον από τον Worker εφόσον το `worker-config.js` έχει ενημερωθεί με το Worker URL.

## Αργότερα με apps.forensiclabs.gr

Όταν ανακτηθεί Cloudflare/DNS για το `forensiclabs.gr`, μπορούμε να αλλάξουμε το Worker από `workers.dev` σε route/custom domain:

```text
https://apps.forensiclabs.gr/download/latencycheck
https://apps.forensiclabs.gr/download/harddisktemp
https://apps.forensiclabs.gr/api/stats
```

Generated: 2026-05-20T02:17:26


## v21 fix — npm notice / NativeCommandError

Η v21 διορθώνει το σφάλμα όπου το `npx wrangler` έγραφε απλό `npm notice` στο stderr και το PowerShell το αντιμετώπιζε σαν `NativeCommandError`.

Δεν χρειάζεται να ξαναεγκατασταθεί το Node.js. Αφού ήδη εγκαταστάθηκε, τρέξε:

```text
21_CONTINUE_CLOUDFLARE_WORKER_DEPLOY.cmd
```

ή ξανά:

```text
20_DEPLOY_CLOUDFLARE_WORKER.cmd
```

Generated v21: 2026-05-20T02:22:08


## v22 fix — Wrangler arguments

Η v22 διορθώνει το σημείο όπου το Wrangler έδειχνε μόνο το help/COMMANDS αντί να εκτελεί:

```text
wrangler whoami
wrangler kv namespace create DOWNLOAD_STATS
```

Αιτία:
Το script δεν περνούσε σωστά τα subcommands στο `npx wrangler`, άρα το Wrangler άνοιγε τη βοήθεια και δεν δημιουργούσε KV namespace.

Για συνέχεια:
```text
22_CONTINUE_CLOUDFLARE_WORKER_DEPLOY.cmd
```

Generated v22: 2026-05-20T02:25:12


## v23 fix — Cloudflare authentication detection

Η v23 διορθώνει το σημείο όπου το Wrangler έγραφε:

```text
You are not authenticated. Please run `wrangler login`.
```

αλλά το script δεν άνοιγε login και συνέχιζε λανθασμένα στο KV namespace.

Νέα συμπεριφορά:
- διαβάζει το output του `wrangler whoami`,
- αν δει `not authenticated`, ανοίγει `wrangler login`,
- μετά ξανακάνει verify με `wrangler whoami`,
- μόνο αν περάσει συνεχίζει σε KV namespace και Worker deploy.

Για συνέχεια:
```text
23_CONTINUE_CLOUDFLARE_WORKER_DEPLOY.cmd
```

Αν το browser login δεν περάσει, υπάρχει fallback:
```text
23_SET_CLOUDFLARE_API_TOKEN_AND_CONTINUE.cmd
```

Generated v23: 2026-05-20T02:27:54


## v24 — Simple START HERE Cloudflare deploy

Η v24 προσθέτει ένα μόνο απλό αρχείο για εκκίνηση:

```text
00_START_HERE_CLOUDFLARE_LOGIN_AND_DEPLOY.cmd
```

Αυτό:
- ανοίγει Cloudflare browser login,
- κάνει verify `wrangler whoami`,
- συνεχίζει μόνο του σε Worker deploy,
- ενημερώνει `worker-config.js`,
- κάνει push στο GitHub Pages.

Το API token fallback μεταφέρθηκε στον φάκελο `advanced`, ώστε να μην χρησιμοποιείται κατά λάθος.

Generated v24: 2026-05-20T02:40:50
