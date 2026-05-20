F.I.C. Windows Utilities - καθαρό site

Τελικό καθαρό URL:
https://apps.forensiclabs.gr/

Τι έχει μπει στο πακέτο:
- CNAME με τιμή: apps.forensiclabs.gr
- canonical/meta URL: https://apps.forensiclabs.gr/
- Worker παραμένει ενεργός στο:
  https://fic-windows-utilities-counters.gvraftogiannis.workers.dev

Τρέξε πρώτα:
33_PUSH_APPS_FORENSICLABS_CUSTOM_DOMAIN.cmd

Μετά πρέπει να γίνει DNS ρύθμιση στο Cloudflare account που έχει το domain forensiclabs.gr.

Cloudflare DNS record:
Type: CNAME
Name: apps
Target: raftog.github.io
Proxy status: DNS only στην αρχή
TTL: Auto

Μετά στο GitHub:
Repository: raftog/FIC-Windows-Utilities-Site
Settings -> Pages -> Custom domain:
apps.forensiclabs.gr

Αν το GitHub δείξει DNS check OK, ενεργοποιείς Enforce HTTPS.

Έλεγχος:
33_CHECK_APPS_DOMAIN.cmd

Σημαντικό:
Αν το domain forensiclabs.gr δεν εμφανίζεται στο τωρινό Cloudflare account, τότε η DNS εγγραφή δεν μπορεί να γίνει από αυτό το account. Πρέπει να μπεις στο Cloudflare account που έχει το zone forensiclabs.gr ή να ανακτηθεί/μεταφερθεί το zone.
