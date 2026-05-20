# F.I.C. Windows Utilities — GitHub Pages Test Deployment

Έτοιμο πακέτο για δοκιμαστικό ανέβασμα σε GitHub Pages.

## Δοκιμαστικό URL μετά το deploy

```text
https://raftog.github.io/FIC-Windows-Utilities-Site/
```

## Στατιστικά

```text
https://raftog.github.io/FIC-Windows-Utilities-Site/#statistics
```

## Πώς το τρέχεις

1. Αποσυμπίεσε το zip.
2. Άνοιξε τον φάκελο `FIC-Windows-Utilities-Site`.
3. Για τοπικό έλεγχο τρέξε:

```text
00_PREVIEW_LOCAL.cmd
```

4. Για ανέβασμα στο GitHub Pages τρέξε:

```text
01_DEPLOY_TO_GITHUB_PAGES.cmd
```

Αν το `gh` δεν είναι logged in, τρέξε πρώτα:

```cmd
gh auth login
```

## Μελλοντική ενημέρωση

Μετά από αλλαγές τρέχεις:

```text
02_UPDATE_SITE_PUSH.cmd
```

## Custom domain αργότερα

Υπάρχει `CNAME.example` με:

```text
apps.forensiclabs.gr
```

Δεν το κάνουμε ακόμη `CNAME` μέχρι να ανακτηθεί Cloudflare/DNS.

Generated: 2026-05-20T01:02:46


## v6 fix

Η v6 διορθώνει το πρόβλημα:

```text
git.exe was not found in PATH
```

Το `Deploy_GitHub_Pages.ps1` πλέον:
- ψάχνει το Git σε συνηθισμένες θέσεις εγκατάστασης,
- αν δεν το βρει, προσπαθεί να εγκαταστήσει Git for Windows με `winget`,
- ενημερώνει προσωρινά το PATH της τρέχουσας εκτέλεσης,
- ψάχνει και το GitHub CLI σε συνηθισμένες θέσεις,
- αν χρειαστεί, εκκινεί `gh auth login`.

Generated v6: 2026-05-20T01:06:23


## v7 fix

Η v7 διορθώνει το νέο σφάλμα:

```text
Author identity unknown
fatal: unable to auto-detect email address
```

και επίσης δεν σταματά λανθασμένα όταν το `gh repo view` δεν βρίσκει ακόμη το repository.
Αν το repo δεν υπάρχει, συνεχίζει σωστά σε `gh repo create`.

Η ρύθμιση `git user.name/user.email` γίνεται μόνο τοπικά στον φάκελο του repository, όχι global στα Windows.

Generated v7: 2026-05-20T01:10:23


## v8 repair for GitHub Pages 404

Η v8 προσθέτει:

```text
03_REPAIR_ENABLE_GITHUB_PAGES.cmd
Repair_Enable_GitHub_Pages.ps1
```

Χρήση όταν το URL:

```text
https://raftog.github.io/FIC-Windows-Utilities-Site/
```

δείχνει GitHub Pages 404.

Το repair:
- ελέγχει `git` και `gh`,
- ελέγχει login,
- σιγουρεύει repository/commit/push,
- δημιουργεί το repo αν λείπει,
- ενεργοποιεί ή ενημερώνει GitHub Pages με source `main` και path `/`,
- ανοίγει το τελικό URL.

Generated v8: 2026-05-20T01:21:01


## v9 fix

Η v9 διορθώνει το σφάλμα:

```text
! [rejected] main -> main (fetch first)
Updates were rejected because the remote contains work that you do not have locally.
```

Τώρα το repair:
- κάνει πρώτα κανονικό push,
- αν απορριφθεί επειδή το remote έχει ήδη commits, κάνει `fetch`,
- συμφιλιώνει το `origin/main` με το τοπικό site μέσω merge,
- αν χρειαστεί για αυτό το νέο site repository, χρησιμοποιεί `--force-with-lease`,
- μετά ενεργοποιεί/διορθώνει GitHub Pages.

Generated v9: 2026-05-20T01:26:09


## v10 fix — Download button 404

Η v10 διορθώνει το πρόβλημα όπου το πλήκτρο «Λήψη τελευταίας έκδοσης» οδηγούσε σε GitHub Pages 404.

Αιτία:
```text
/download/latencycheck
/download/harddisktemp
```

Αυτά τα routes χρειάζονται Cloudflare Worker. Στο προσωρινό GitHub Pages test site δεν υπάρχουν.

Διόρθωση:
- Για το GitHub Pages test site, τα download buttons δείχνουν απευθείας στα GitHub Release assets:
  - LatencyCheck latest installer
  - HardDiskTemp latest installer
- Όταν αργότερα μπει Cloudflare Worker, μπορούμε να επαναφέρουμε τα `/download/...` routes για μετρητή χώρας/downloads.

Για ανέβασμα της διόρθωσης τρέξε:
```text
04_PUSH_DOWNLOAD_LINK_FIX.cmd
```

Generated v10: 2026-05-20T01:31:01


## v11 fix — Internal Changelog

Η v11 αλλάζει τα πλήκτρα «Ιστορικό αλλαγών» ώστε να μη στέλνουν τον απλό επισκέπτη απευθείας στη σελίδα GitHub Release.

Νέα συμπεριφορά:
- `Ιστορικό αλλαγών` → εσωτερικό section `#changelog` μέσα στο site.
- Το section φορτώνει release title/notes από GitHub API.
- Η τεχνική GitHub release page μένει μόνο ως δευτερεύον link για τεχνικό έλεγχο.
- Τα Download buttons παραμένουν direct στα GitHub Release assets.

Για ανέβασμα:
```text
05_PUSH_INTERNAL_CHANGELOG_FIX.cmd
```

Generated v11: 2026-05-20T01:36:00


## v12 fix — Remove public GitHub links from Links section

Η v12 αφαιρεί τα δύο εμφανή links:
- `LatencyCheck GitHub`
- `HardDiskTemp GitHub`

και τα αντικαθιστά με εσωτερικά links:
- Περιγραφή και τρόπος λειτουργίας LatencyCheck
- Περιγραφή και τρόπος λειτουργίας HardDiskTemp

Προστέθηκε νέο εσωτερικό section:
```text
#program-operation
#latencycheck-operation
#harddisktemp-operation
```

Για ανέβασμα:
```text
06_PUSH_REMOVE_GITHUB_LINKS_ADD_OPERATION.cmd
```

Generated v12: 2026-05-20T01:39:27


## v13 fix — Counters

Η v13 προσθέτει πλήρη εμφάνιση μετρητών στο section `#statistics`.

Στο GitHub Pages test site λειτουργούν άμεσα:
- Λήψεις LatencyCheck από GitHub Release asset download_count
- Λήψεις HardDiskTemp από GitHub Release asset download_count
- Σύνολο λήψεων

Για μελλοντικό `apps.forensiclabs.gr` με Cloudflare Worker προστέθηκαν:
- `POST /api/visit` για μετρητή επισκέψεων
- `GET /api/stats` για δημόσια συγκεντρωτικά στατιστικά
- `/download/latencycheck` και `/download/harddisktemp` για μετρητή downloads ανά εφαρμογή και χώρα
- KV storage χωρίς αποθήκευση IP

Για ανέβασμα στο GitHub Pages:
```text
07_PUSH_COUNTERS_FIX.cmd
```

Σημείωση:
Στο προσωρινό GitHub Pages οι χώρες/επισκέψεις δείχνουν «Ενεργοποίηση με Worker», επειδή το GitHub Pages δεν τρέχει backend.
Οι μετρητές λήψεων ανά εφαρμογή δουλεύουν ήδη μέσω GitHub API.

Generated v13: 2026-05-20T01:41:35
