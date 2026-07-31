# INCIDENT LEDGER — Vendor Cooling-Off Register

> Machine-readable register of vendors currently in a post-incident cooling-off period.
> Consumed by `scripts/lib/advisory-check.sh`. Format is strict — do not reformat.
>
> **Rule:** Any author/vendor with a publicly disclosed security incident in the last
> 90 days is auto-demoted from the Trust Gate allowlist to full Tier C scrutiny.
> Re-admission requires: (a) 90 days since incident closure, (b) published post-mortem,
> (c) verified supply chain integrity.

## Active cooling-off periods

The lines below are parsed by regex: `^COOLING_OFF:\s+<owner>/...\s+until\s+<YYYY-MM-DD>`

_None active._

> **Parser note (load-bearing — do not ignore when editing this file):**
> `is_in_cooling_off()` in `scripts/lib/advisory-check.sh` — its
> `while IFS= read -r line; … done < "$LEDGER"` loop — reads this file **line by line with
> no awareness of which section a line sits in.** Any line anywhere in this file that
> starts with `COOLING_OFF:` is parsed, including inside fenced code blocks (the loop is
> not markdown-aware). Expired entries are therefore recorded in the table below
> **without** the line-start prefix, so they cannot be re-parsed. Never move a live
> `COOLING_OFF:` line into the expired section verbatim.
>
> **Known exception:** the `## Format reference` section at the end of this file DOES
> contain a line-start `COOLING_OFF:` template. It is inert only because its placeholder
> date `<YYYY-MM-DD>` fails the parser's `[0-9-]+` class — `COOLING_OFF: acme/* until
> 2027-01-01` WOULD match. Never replace that placeholder with a realistic date.
> Consequence: `grep -c "^COOLING_OFF:" <this file>` returns 1, not 0, even when no
> vendor is in cooling-off. Tracked in `docs/BACKLOG.md` (2026-07-31 residuals entry).

## Entry details

_No active entries._

## Expired entries (historical — do not re-enable without review)

Recorded in table form deliberately — see the parser note above.

| Owner | Incident | Cooling-off ran | Expired | Re-admission criteria met? |
|---|---|---|---|---|
| `vercel/*`, `vercel-labs/*` | 2026-04-19 | 2026-04-21 → 2026-07-20 (90 days) | 2026-07-20 | **(a) only — see below** |

### vercel/* and vercel-labs/* — EXPIRED 2026-07-20, reconciled 2026-07-31
- **Incident date:** 2026-04-19
- **Cooling-off ran until:** 2026-07-20 (90 days)
- **Source:** https://vercel.com/kb/bulletin/vercel-april-2026-security-incident
- **Summary:** Unauthorised access to Vercel internal systems via compromised third-party
  AI tool (Context.ai) → employee Google Workspace takeover → Vercel environments.
  Limited non-sensitive env vars exposed. npm packages confirmed not compromised per
  Vercel + GitHub + Microsoft + npm + Socket.
- **Rationale for cooling-off despite clean supply chain:** "Believed safe" ≠ "proven clean."
  Forensics post-window; cooling-off is elevated scrutiny, not an accusation. Vercel-labs
  also owns the `find-skills` skill (1.1M installs) which would otherwise be a default
  install — we use our own `/scout` wrapper instead.
- **Re-admission criteria:** Public post-mortem + 90 days of clean operations + one
  independent supply-chain review.
- **Status of those criteria as of 2026-07-31 (honest record — do not upgrade without evidence):**
  - (a) 90 days of clean operations — **MET.** Window closed 2026-07-20.
  - (b) Published post-mortem — **NOT VERIFIED.** No one has checked for one. The URL
    above is the original incident bulletin, not a post-mortem.
  - (c) Independent supply-chain review — **NOT VERIFIED.** No such review exists in
    this repo or any linked artefact.
- **What expiry actually changed (verified against `scripts/lib/advisory-check.sh`, 2026-07-31):**
  Expiry did **NOT** re-admit vercel to the allowlist, and criteria (b) and (c) are not
  bypassed. Traced flow through `advisory_check()` for owner `vercel`: `is_in_cooling_off()`
  now returns false (its date comparison `"$today" < "$until_date"` no longer holds) →
  `is_self_hosted()` false → `is_allowlisted()` false, because neither `vercel` nor
  `vercel-labs` appears in the **`ALLOWLIST=(…)` array** → falls through to the final
  `UNKNOWN — requires full Tier C pipeline` branch. So the posture moved
  **BLOCKED → FULL-SCRUTINY**, never **BLOCKED → auto-pass.** Allowlist admission is a
  separate manual edit of that array, which nobody has made and which criteria (b) and (c)
  gate. **Doctrine and code agree — there is no gap here.**
  > Citations here name **functions and variables, never line numbers** — deliberately.
  > The first version of this paragraph cited line numbers, then the same changeset added
  > comment lines to `advisory-check.sh` and shifted every one of them; the citation for
  > "UNKNOWN" ended up pointing at `return 0`, the auto-pass. Symbols survive edits; line
  > numbers do not. Reproduce this trace from **any** working directory:
  > `bash -c 'source ~/claude-hq/scripts/lib/advisory-check.sh; advisory_check https://github.com/vercel/next.js'`
  > → expect `UNKNOWN — vercel requires full Tier C pipeline`, exit code 2.
  > (The path is absolute deliberately: the first version used a relative one and printed
  > `command not found` from anywhere else — which reads as "the gate was deleted".)
- **To actually re-admit** (not currently proposed): satisfy (b) and (c) with linked
  artefacts, then add the owners to `ALLOWLIST` in `scripts/lib/advisory-check.sh` and to
  the allowlist in `commander/TRUST_GATE.md`. Until then vercel stays UNKNOWN, which is
  the correct conservative default and needs no action.

## Format reference (for future entries)

```
COOLING_OFF: <github-owner>/* until <YYYY-MM-DD>
```
Then a prose block following the template above. Keep entries even after expiry —
the history is useful for future trust decisions.
