// HQ WORKFLOW TEMPLATE — copy + adapt. The guardrails below are NON-NEGOTIABLE.
// Read SKILL.md first. Fill the CONFIG block, then the TASK section. Do not remove the
// guardrail comments — they are the contract this template enforces.
//
// meta MUST be a pure literal (no variables/calls). phases titles must match phase() calls.
export const meta = {
  name: 'CHANGE-ME',                 // kebab-case
  description: 'CHANGE-ME — one line, shown in the permission dialog.',
  phases: [
    { title: 'Work' },
    { title: 'Verify' },
  ],
}

// ── GUARDRAIL CONFIG (set these from the SKILL.md pre-flight estimate) ────────────────
const MAX_AGENTS = 8          // HARD cap. GREEN ≤8. Raising past 8 = AMBER (needs approval).
const MAX_VERIFY_CYCLES = 3   // Circuit breaker (K). After this, HALT and flag for human.
const GRUNT_MODEL = 'sonnet'  // read/find/transform agents. Use 'haiku' for pure mechanical.
// Synthesis/verify: omit model (inherit Opus) — calibre is decided there.

// ── TASK (edit this) ─────────────────────────────────────────────────────────────────
const ITEMS = args && Array.isArray(args) ? args : [/* fill, or pass via args */]

// Schemas keep returns compact + validated (cheaper + no parsing).
const RESULT_SCHEMA = {
  type: 'object',
  properties: { findings: { type: 'array', items: { type: 'object',
    properties: { title: { type: 'string' }, detail: { type: 'string' } },
    required: ['title', 'detail'] } } },
  required: ['findings'],
}
const VERDICT_SCHEMA = {
  type: 'object',
  properties: { verified: { type: 'array', items: { type: 'object',
    properties: { title: { type: 'string' }, isReal: { type: 'boolean' }, reason: { type: 'string' } },
    required: ['title', 'isReal', 'reason'] } } },
  required: ['verified'],
}

// ── GUARDRAIL: hard agent-count check before doing anything ───────────────────────────
let agentCount = 0
const work = ITEMS.slice(0, MAX_AGENTS)   // never fan out beyond the cap
if (ITEMS.length > MAX_AGENTS) {
  log(`⚠️ ${ITEMS.length} items but MAX_AGENTS=${MAX_AGENTS}. Capped — ${ITEMS.length - MAX_AGENTS} dropped. Re-scope or raise the cap WITH approval.`)
}

// ── PIPELINE (default): each item streams Work → Verify with no barrier ───────────────
const results = await pipeline(
  work,
  // Stage 1 — Work (grunt tier). Give a TIGHT brief + TARGETED reads. Context = 91% of cost.
  (item, _orig, i) => {
    agentCount++
    return agent(
      `TIGHT BRIEF for item ${i}: ${JSON.stringify(item)}\n` +
      `Read ONLY what you need. Return concise structured findings. Do not pad.`,
      { label: `work:${i}`, phase: 'Work', model: GRUNT_MODEL, schema: RESULT_SCHEMA }
    )
  },
  // Stage 2 — Adversarial verify (Opus). MANDATORY for any claim/finding/code.
  (res, item, i) => {
    if (!res || !res.findings || !res.findings.length) return { item: i, confirmed: [] }
    agentCount++
    return agent(
      `Adversarially verify each claimed finding against ground truth. Default skeptical; ` +
      `mark isReal=false if you cannot confirm it.\n` +
      res.findings.map((f, n) => `${n + 1}. ${f.title} — ${f.detail}`).join('\n'),
      { label: `verify:${i}`, phase: 'Verify', schema: VERDICT_SCHEMA }
    ).then((v) => {
      const ok = new Map((v?.verified || []).map((x) => [x.title, x]))
      return {
        item: i,
        confirmed: res.findings.filter((f) => ok.get(f.title)?.isReal)
          .map((f) => ({ ...f, why: ok.get(f.title).reason })),
        rejected: res.findings.length - res.findings.filter((f) => ok.get(f.title)?.isReal).length,
      }
    })
  }
)

// ── Aggregate in PLAIN CODE (not an agent — saves a whole agent's worth of tokens) ─────
const clean = results.filter(Boolean)
const confirmed = clean.flatMap((r) => r.confirmed || [])

// NOTE on the circuit breaker (K): if your task needs a fix→re-verify loop, wrap it in a
// `for (let cycle = 0; cycle < MAX_VERIFY_CYCLES; cycle++)` — NEVER a while(true). After
// MAX_VERIFY_CYCLES, return partial results with needsHuman:true. Do not loop a fix forever.

return {
  // Post-run: the Commander logs the REAL token total from the task-notification
  // usage.subagent_tokens — NOT budget.spent() (which undercounts ~11×).
  meta: { agentsSpawned: agentCount, maxAgents: MAX_AGENTS, outputTokensOnly: budget.spent() },
  confirmedCount: confirmed.length,
  confirmed,
  needsHuman: false,
}
