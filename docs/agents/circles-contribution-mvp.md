# Circles / Groepies — contribution MVP

Round contributions use **MULTI payment links** created by the host via:

`POST /v1/circles/:id/contribution-link`

The link amount equals `contributionCents`, `maxUses` equals active member count, and expiry follows `cycleDurationDays`. Members pay through the existing payer web + Yapily flow — no client-side payment logic.

Host advances rounds manually with `POST /v1/circles/:id/advance-round` after collections are complete.
