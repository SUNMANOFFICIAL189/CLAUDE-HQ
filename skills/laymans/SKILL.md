---
name: laymans
description: >-
  Re-express technical content in plain English for a non-engineer, on demand. Triggered by
  /laymans or any of: "explain in laymen's/layman's terms", "in plain English", "explain simply",
  "dumb it down", "what does this mean for me", "ELI5". Translates the LAST technical answer (or a
  named target) into jargon-free language WITHOUT losing accuracy or dropping the caveats that matter.
  Use whenever the operator wants the plain-English version — they ask for this often. Sibling to the
  HQ plain-English + CTDD communication doctrine.
---

# /laymans — plain-English translation (accurate, not dumbed-down)

Turn technical output into something a smart non-engineer gets immediately — the way the security
work this codebase did got explained as "a guard at a gate," timeouts as "give-up timers," fail-open
as "the guard flings the gate open when it trips." Clarity, not condescension.

## When to use
- The operator says "explain in laymen's terms / plain English / simply" (or /laymans).
- After any technical answer, review, or decision that the operator needs to *act on* but isn't
  going to read jargon for.
- Default register reminder: this operator's user-facing register is **plain English** already
  (see `feedback_communication_plain_english_ctdd` + `commander/COMMUNICATION.md`). This skill is the
  explicit "go further / translate that last thing" gear.

## The rules (what makes it good)
1. **Bottom line first.** One sentence: what it means / what to do. Then the detail.
2. **No jargon. If a term is unavoidable, define it in-line** with a plain analogy the first time
   (e.g. "a *hook* — a script the system runs automatically at a certain moment").
3. **Use analogies for mechanisms** (guard/gate, restore-point, give-up timer, conveyor belt) —
   concrete, everyday objects.
4. **Keep it accurate. Do NOT lose the caveats.** Plain ≠ wrong. If something is "fixed but not
   bulletproof," say exactly that. Translating away a real risk is a failure, not a simplification.
5. **Short sentences. Tables/bullets over walls of prose.** Lead each item with the "so what."
6. **Preserve the decision.** If the technical answer ended in "your call: A / B / C," the plain
   version must still end with that same choice, in plain words — never quietly drop the ask.
7. **Numbers stay.** Keep the concrete figures (cost, counts, dates) — just unpack what they mean.
8. **Flag honestly.** If the underlying thing is uncertain or unverified, the plain version says
   "we don't actually know yet," not a false-confident summary.

## How to run
1. Identify the target: the LAST technical message, or whatever the operator points at.
2. Re-express it per the rules above. Map each technical claim → plain statement, each mechanism →
   analogy, each risk/caveat → plain warning (kept, not dropped).
3. End with the same decision/next-step the technical version had, in plain words.

## Anti-patterns
- **Dropping caveats to sound clean** — the #1 failure. Keep every "but / however / not yet."
- **Over-simplifying into inaccuracy** — if the analogy breaks the meaning, pick a better analogy.
- **Burying the answer** — bottom line goes first, not last.
- **Adding new claims** — translate what was said; don't invent reassurance.

## Pairs with
`adversarial-review` / `proof-check` (whose findings often need a plain-English readout for the
operator to decide), `ctdd-precheck`, and the `commander/COMMUNICATION.md` doctrine.
