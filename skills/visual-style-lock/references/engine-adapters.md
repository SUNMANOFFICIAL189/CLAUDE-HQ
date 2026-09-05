# Engine adapters

The core method in SKILL.md is engine-agnostic. Each engine needs an adapter that defines five things. Use the live adapter below. To add an engine, copy the contract and fill it; the core method does not change.

## Adapter contract (what every engine must define)

1. Generate call: the tool and the parameter shape.
2. Anchoring: how to attach a reference image, and what reference types are accepted.
3. Aspect ratios: the supported set, and any unsupported ratios to avoid.
4. Resolution and quality: the parameter names and the values for test vs final.
5. Limits and caveats: timing, what the agent cannot see, and any I/O constraints with a workaround.

---

## Live adapter: Higgsfield + GPT Image 2

### 1. Generate call
- Tool: `generate_image` on the Higgsfield MCP server.
- Shape: `{ model, prompt, aspect_ratio, resolution, quality, count, medias[] }` passed inside `params`.
- Model lock: `gpt_image_2`. This project's standing rule is GPT Image 2 only. It renders under the internal model id `imagegen_2_0`.
- Preflight cost: set `get_cost: true` to return credit cost without submitting.

### 2. Anchoring (the consistency lever)
- Attach references in `medias`: a list of `{ value, role: "image" }`.
- `value` accepts a prior generation's job id, an uploaded media UUID, or an https URL.
- Pass the grade anchor (the approved frame) to hold colour. Pass the brand-asset media (the uploaded logo) on branded shots. Both can ride in the same `medias` array.
- Composition risk: a people-heavy anchor can pull extra figures into a frame meant for one subject. For single-subject shots, anchor the asset only and carry the grade in text once the grade clause is proven. For groups, anchor both grade and asset.
- Always pair the anchor with the clause: "Match the colour, white balance and grade of the reference image exactly."

### 3. Aspect ratios
- Supported: `1:1`, `4:3`, `3:4`, `16:9`, `9:16`, `3:2`, `2:3`.
- Not supported: `4:5`. Use `3:4` for the feed portrait.

### 4. Resolution and quality
- `resolution`: `1k`, `2k`, `4k`. `quality`: `low`, `medium`, `high`.
- Default for tests and composition passes: `1k`. The look locks fine at 1k.
- Final, only on operator request: `2k` or `4k` with `quality: high`.

### 5. Limits and caveats
- The agent cannot see its own generated images by default — this is specific to this engine's UI-only rendering; results render into the operator's UI, not back into the agent's context. Present every result with `job_display` and let the operator validate. If `results.rawUrl` is fetched to disk (for example via a download step), the agent CAN open that local file and should run the Step 6b element check on it first; absent that, validation falls to the operator alone. Never assert a render matches without a check.
- Polling: a `generate_image` call returns a `pending` job. GPT Image 2 at high quality runs roughly 60 to 120 seconds. Wait, then call `job_display` with the job id; repeat until `status: completed`, then read `results.rawUrl`.
- Display one job per `job_display` call.
- Upload constraint: the sandbox shell cannot push files to the Higgsfield CDN (egress allowlist blocks the host). The operator uploads the brand asset into Higgsfield directly, then it is referenced by media id. Find the id with `show_medias`. The operator-facing "allowed domains" setting does not govern the shell sandbox.
- Useful tools: `job_display` (show one result), `show_generations` (browse past jobs and reuse a job id as an anchor), `show_medias` (list uploaded assets and their ids), `balance` / `show_plans_and_credits` (credits).

### Validated recipe (the pattern this adapter was built from)
1. Dissect the operator's reference into a plain grade clause.
2. Generate one 1k test, text-only, to let the grade express, or anchored once an anchor exists.
3. On approval, treat that frame as the grade anchor.
4. Produce proportions at 1k, reusing the prompt and attaching the grade anchor (and the asset on branded shots).
5. Step approved frames to 2k/4k only when asked.

---

## Live adapter: AtlasCloud + GPT Image 2 (edit)

### 1. Generate call
- Endpoint: `POST https://api.atlascloud.ai/api/v1/model/generateImage`.
- Header: `Authorization: Bearer <key>` — the key comes from the macOS Keychain, never a file.
- Body: `{ "model": "openai/gpt-image-2/edit", "prompt": "...", "images": ["..."], "size": "2048x1152", "quality": "medium", "output_format": "png", "enable_sync_mode": false, "enable_base64_output": false }`.
- Model ids: `openai/gpt-image-2/edit` (OpenAI-org listing; prefer this for fidelity) and `openai/gpt-image-2-developer/edit` (same schema, half price, listed under a different org — treat as a relay; use only if cost dominates).
- Text-to-image variants exist with the same shape minus `images`.

### 2. Anchoring (the consistency lever)
- `images`: 1–10 strings, each an https URL OR a base64 `data:image/png;base64,...` URI (verified accepted).
- Order matters — this is the "reference order" operating rule in practice: the first image dominates scene and composition; later images steer specific attributes (a second reference can change the shape of a subject's eyewear or a prop). Scene anchor first, identity or other references after, never the reverse.

### 3. Aspect ratios
- Governed by the `size` enum, not a ratio field: `1024x1024`, `1024x768`, `768x1024`, `1024x1536`, `1536x1024`, `2048x2048`, `2048x1152`, `1152x2048`, `2560x1088`, `1088x2560`, `2880x2160`, `2160x2880`, `3840x2160`, `2160x3840`.
- There is no 1k 16:9 size. The smallest true 16:9 is `2048x1152` — use it for tests. Use `3840x2160` for approved finals.

### 4. Resolution/quality and real cost
- `quality`: `low` | `medium` | `high`.
- Prices are NOT flat. The model page's headline "$0.01 per image" is not what is actually charged. Quote before spend, for free: `POST https://api.atlascloud.ai/api/v1/model/calculate` with `{ model, prompt, images, size, quality }` → read `data.price`. Price scales with size × quality × number of input images.
- Measured 2026-09-05 for `openai/gpt-image-2/edit`: `2048x1152` medium ≈ $0.06 with one reference, +≈$0.01 per extra reference; `3840x2160` medium ≈ $0.13, high ≈ $0.43; low ≈ one third of medium; the developer variant ≈ half these figures.
- Wallet: `GET https://api.atlascloud.ai/public/v1/balance`.
- Spend history: `GET https://api.atlascloud.ai/public/v1/model-costs?start_date=&end_date=`.

### 5. Limits and caveats
- Poll `GET https://api.atlascloud.ai/api/v1/model/result/{request_id}` → `data.status` (`created` / `processing` / `completed` / `failed`); the image URL sits at `data.outputs[0]` (signed, expiring — download immediately). Note this is NOT the `/model/prediction/{id}` path used by this platform's video models.
- Roughly 50–65 seconds per still at `2048x1152` medium.
- The result payload carries no price field. Reconcile real cost from the wallet delta or the model-costs endpoint — never assume.
- No fidelity/preserve flag exists: the model regenerates from the references, it does not inpaint. Any text present in the prompt may be rendered as literal text in the image — strip dialogue before building the prompt.
- In-flight requests cannot be cancelled and are charged even if the client dies. Never retry after a successful submit; retry only if the submit call itself failed with no request id returned. A saved file on disk is success; wrap all later bookkeeping so it can never trigger a retry.
- The agent CAN open the downloaded PNG and must run the Step 6b element check on it.

### Pseudo-code sketch
```
quote = POST /model/calculate {model, prompt, images, size, quality}
assert quote.data.price is affordable
balance = GET /public/v1/balance
if balance < quote.data.price: stop, tell operator

result = POST /model/generateImage {model, prompt, images, size, quality, ...}
request_id = result.data.id           # the platform calls it `id`; only retry if THIS call failed

loop:
  status = GET /model/result/{request_id}
  if status.data.status == "completed": break
  if status.data.status == "failed": stop, do not blindly retry
  wait a few seconds

url = status.data.outputs[0]          # signed, expiring
download url -> local_file            # bookkeeping from here can never trigger a retry

open(local_file)                            # agent CAN see this
run element_check(local_file, inventory)    # Step 6b
present to operator for taste/grade gate
```

---

## Stub: adding a new engine

Copy the adapter contract above and answer all five points for the new engine. Keep the core method, the operating rules, and the gated workflow exactly as written in SKILL.md. Only the five adapter facts change. Record the new engine in the project STYLE_LOCK Section 0 and Section 6.
