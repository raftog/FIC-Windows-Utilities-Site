F.I.C. Windows Utilities - Cloudflare Worker

ΤΡΕΞΕ ΜΟΝΟ ΑΥΤΟ:

00_START_HERE_CLOUDFLARE_LOGIN_AND_DEPLOY.cmd

Η v25 διόρθωσε το προηγούμενο σφάλμα PowerShell parser/encoding.
Το εκτελέσιμο PowerShell script είναι πλέον ASCII-only, ώστε να μην χαλάει από ελληνικούς χαρακτήρες.

ΜΗΝ τρέξεις API token fallback.
ΜΗΝ πατήσεις Add domain.
ΜΗΝ φτιάξεις domain τώρα.

Το script θα ανοίξει browser.
Κάνεις Cloudflare login και πατάς Allow / Authorize για Wrangler.

Μετά συνεχίζει μόνο του:
- Worker deploy
- KV namespace
- ενημέρωση worker-config.js
- push στο GitHub Pages

Αν θες απλό έλεγχο login μόνο:
00_ONLY_CLOUDFLARE_LOGIN_TEST.cmd
