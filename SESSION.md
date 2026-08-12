# PCS Private Lending — Session Handoff

_Last updated: **2026-06-22 (Sat)**. Hand this whole file to Claude in any context; it is self-contained._

---

## TL;DR
PCS Private Lending is a **static real-estate-loan lead-gen landing page** (Fix & Flip, Construction, DSCR, Multifamily). The code is **built, pushed, and deployed**, and leads now save into a **shared Supabase CRM** with a role-gated `/admin` dashboard. It is **NOT live on its real domain** because the Vercel project sits in the wrong (imposter) team, and as of **06/22/26 it is PARKED** — the move is deliberate and not urgent.

> Master record: `Downloads\Infrastructure-Reconciliation-Auth-Decision-06-22-26.md` (source of truth across all Five Stone builds). The auth architecture question is now **DECIDED** there: shared identity + isolated data per app + per-app `app_access` gate.

**🛑 Do NOT push, re-deploy, move, or build anything here until Cyrus walks through the re-import cutover. No build authorized (Building Rule).**

---

## What this is
- **Repo:** `kingcdk1/pcs-private-lending` (GitHub, **public**). Local clone: `C:\Users\Cyrus\Downloads\pcs-private-lending-repo`.
- **Type:** single static page, no build step. `public/index.html` (landing + 3-step form), `public/admin.html` (leads dashboard), `vercel.json`, `SUPABASE_LEADS_SETUP.sql`.
- **Intended domain:** `lending.pcstaxservice.com`.

## Architecture (as built today)
| Layer | Where | Notes |
|---|---|---|
| Front-end | static HTML in repo | PCS navy/blue theme, Meta pixels `911406421368178` + `4267435563472349` |
| Hosting | Vercel project `pcs-private-lending` | **⚠ in the WRONG team — see blocker** |
| Backend (auth + data) | **SHARED** Supabase project `gcrzmiwgjvuujffbqjbq` | same project as Revenue Board; this is the AutoCloud/CRM "one brain" |
| Domain/DNS | GoDaddy (`ns23/ns24.domaincontrol.com`) | CNAME `lending` → `cname.vercel-dns.com` already added ✅ |

## What's DONE and VERIFIED
- ✅ Replaced the dead GoHighLevel webhook placeholder (it was silently dropping every lead) with a Supabase insert into `public.leads`, plus a `mailto` fallback so a lead is never lost.
- ✅ Built `public/admin.html`: Google + email-link login, **role-gated to admin/manager** via `profiles.role`, with search, type/status filters, inline status edits, CSV export.
- ✅ Ran `SUPABASE_LEADS_SETUP.sql` in Supabase (idempotent): created `public.leads`, added `profiles.role` (admin|manager|staff), auto-create-profile trigger, RLS policies (public can INSERT; only admin/manager can SELECT/UPDATE), and promoted `fivestoneinvestments@gmail.com` to admin.
- ✅ DB verified end-to-end against live Supabase: anon INSERT works (HTTP 201), anon READ blocked by RLS (returns `[]`). One **"TEST DeleteMe"** row was left in `leads` as proof — delete it via Supabase → Table Editor.
- ✅ Pushed to `main` (commit `17cfec1`) → Vercel auto-built (deployment READY). Deployed `/admin` verified 200 via Vercel authenticated fetch.
- ✅ GoDaddy CNAME for `lending` added and confirmed at the authoritative nameserver.

## 🅿️ PARKED — Vercel team mismatch (why it's not live)
The lending project lives in the **imposter Vercel team** (the 1-800-MyAutos account renamed to look like Five Stone; the slug gives it away), which is a **different team than the domain**. Vercel cannot attach a domain across teams, so "Add Domain" silently fails and **no SSL cert is issued** (TLS handshake fails → site returns nothing). This is the only reason it never resolved.

- `pcs-private-lending` project → **IMPOSTER** team `www1800myautoscom` (id `team_xoKO3yv03GOcIJl69rtpzRIP`)
- `pcstaxservice.com` domain + all real apps → **REAL** team `five-stone-investments` (id `team_4X7y56eHmpUYpH5HpQdac9k3`)

**Move approach (DECIDED, but PARKED — walk through risk before executing):** Vercel has no one-click cross-team move, so:
1. Re-import the GitHub repo as a **new** project in the `five-stone-investments` team.
2. Cut the domain `lending.pcstaxservice.com` over to it (CNAME already set → attaches + cert in ~1 min).
3. Delete the old project in the imposter team.

There is a live-domain cutover in the middle, so do it in a clean window, not at the end of a long session. **Gotcha for all future deploys: confirm the Vercel team SLUG, not just the display name.**

## ✅ DECIDED — auth architecture (was the open question)
Settled 06/22/26 in the master reconciliation doc: **shared identity + isolated data per app + per-app `app_access` gate.** One person = one permanent UID across all apps; each app keeps its OWN tables (the Sat accounting/lending leads-table collision was a table problem, not a project problem); access to each app is gated by a per-app `app_access` table (prototyped in the PCS Compliance session, branch `supabase-auth`, not pushed). Access model: per-site toggle, controlled in-app, **visible by default**, sensitive sites flagged.

**What this means for lending:** the `leads` RLS here currently uses the **global** `profiles.role`. When the access board is built, migrate it to the per-app `app_access` model. **No build authorized yet (Building Rule — toggle board must be explained + approved first).**

## 🔍 Account/team placement to AUDIT (the "wrong project" worry)
- **Vercel:** confirmed wrong — lending is under `www1800myautoscom`, should be `five-stone-investments`. (Fix above.)
- **GitHub:** repo is under personal account `kingcdk1` (not an org). All repos are there; no org mismatch, but confirm this is the intended home. Repo is **public** — fine for the anon key (public-safe) but the SQL/structure are visible.
- **Supabase:** project `gcrzmiwgjvuujffbqjbq` — **confirm which Supabase org/account owns it** and that it's the intended "Five Stone-owned" account, not a stray one.

## Exact remaining steps to go live (after decisions)
1. Transfer Vercel project to `five-stone-investments` team (blocker above).
2. Add `lending.pcstaxservice.com` domain in that project.
3. Supabase → Authentication → URL Configuration: set Site URL `https://lending.pcstaxservice.com` and add redirect `https://lending.pcstaxservice.com/**`.
4. Log in at `https://lending.pcstaxservice.com/admin` with Google (auto-promoted to admin) → confirm you see leads → delete the TEST row.
5. Final live check: load home, submit a real test lead, confirm it lands in `/admin`.

## Key references
- **Supabase URL:** `https://gcrzmiwgjvuujffbqjbq.supabase.co` (anon key is in `config`-style globals in both HTML files; public-safe).
- **Vercel project id:** `prj_nL5S8vqd6suU2x0D8qOUr8zUV7zC` (currently team `team_xoKO3yv03GOcIJl69rtpzRIP`).
- **Latest deploy:** `dpl_GkRLPo1P2iajP9gSnBJn55qbk2Vg` (commit `17cfec1`, READY).
- **Related projects:** Revenue Board (`pcs-revenue`, `revenue.pcstaxservice.com`) shares the same Supabase backend; this is the CRM seed (AutoCloud).
