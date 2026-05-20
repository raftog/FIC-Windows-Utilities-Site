F.I.C. Windows Utilities - V27 existing KV fix

Το προηγούμενο log έδειξε ότι το KV namespace DOWNLOAD_STATS υπάρχει ήδη.
Η παλιά έκδοση προσπαθούσε να το ξαναδημιουργήσει και σταματούσε.

Τρέξε:

27_CONTINUE_WORKER_DEPLOY_USE_EXISTING_KV.cmd

Η v27:
- κάνει list στα KV namespaces
- βρίσκει το υπάρχον DOWNLOAD_STATS
- γράφει το id στο wrangler.toml
- συνεχίζει Worker deploy
- αν ζητηθεί workers.dev subdomain, ανοίγει onboarding και περιμένει ENTER
