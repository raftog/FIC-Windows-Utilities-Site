F.I.C. Windows Utilities - workers.dev setup

Το προηγούμενο log έδειξε ότι:
- Cloudflare login πέρασε
- KV namespace υπάρχει
- Worker ανέβηκε ως upload
- αλλά λείπει workers.dev subdomain

Τρέξε:

26_REGISTER_WORKERS_DEV_AND_DEPLOY.cmd

Αν ανοίξει Cloudflare onboarding:
1. Φτιάχνεις workers.dev subdomain.
2. Προτεινόμενο όνομα: fic-windows-utilities ή gvraftogiannis
3. ΔΕΝ βάζεις custom domain.
4. Γυρνάς στο CMD και πατάς ENTER.

Μετά το script ξαναδοκιμάζει deploy και ενημερώνει το GitHub Pages site.
