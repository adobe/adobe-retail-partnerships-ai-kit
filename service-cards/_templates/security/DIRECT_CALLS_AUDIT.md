---
last_updated: "<fill: YYYY-MM-DD>"
findings_present: "TODO"   # yes — this file exists only when findings exist
---

# Direct Calls Audit — Security

*Security/integration findings for this engagement (card-model
[§4.6](../../../manual/methodology/card-model.md)).*

> **This file is produced ONLY when findings exist.** Its very presence in
> `service-cards/security/` is a **go-live BLOCKER signal** — every finding below
> must be remediated (or explicitly waived by the partner) before release.
> If no findings exist, this file should not be created.
>
> Grounded in [`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md):
> **rule 9** (secret containment — IMS credentials / `*_CLIENT_SECRET` must appear
> only in the backend surface; frontend repos are grepped and must fail loudly if
> any leaked) and **rule 7** (the partner owns inbound-endpoint auth — validate
> using their registered mechanism, never invent one).

---

## 1. Direct frontend → Adobe calls

*Any call made from a `mobile` / `ios` / `android` / `web` surface **directly to
Adobe** (IMS or the Retail API). These violate the backend-proxy
invariant and are security blockers. One row per call site; cite `File:line`.*

| File:line | Call | Severity | Remediation |
|---|---|---|---|
| `<fill: path:line>` | `<fill: URL / SDK method>` | `<fill: blocker/high/med>` — TODO | `<fill: route through partner backend>` — TODO |
| TODO | TODO | TODO | TODO |

## 2. Secret-leakage checks

*IMS credentials or `*_CLIENT_SECRET` (and any Adobe token-issuing config) found
in a **frontend** repo. Per verification **rule 9** these must appear only in the
backend surface; the check inspects **names**, not values. One row per leaked
name.*

| File:line | Secret name | Surface |
|---|---|---|
| `<fill: path:line>` | `<fill: e.g. ADOBE_IMS_CLIENT_SECRET>` | `<fill: mobile/web/ios/android>` — TODO |
| TODO | TODO | TODO |

## 3. Inbound-auth clarity

*Any partner-hosted endpoint (e.g. the Adobe Notify webhook) whose auth mechanism
is **unclear** from the partner's code/cards, or is **not one of the five**
registered types (`STATIC` / `BASIC` / `CUSTOM_HEADERS` /
`OAUTH2_CLIENT_CREDENTIALS` / `CUSTOM_TOKEN`). Per verification **rule 7** these
must be resolved by **asking the partner** before code is generated — never
force-fit or fabricate a mechanism. See
[`../../../knowledgebase/api-spec/notify-api.md`](../../../knowledgebase/api-spec/notify-api.md).*

| Endpoint | Hosting surface | Observed / registered auth | Why unclear | Question for partner |
|---|---|---|---|---|
| `<fill: path>` | `<fill>` | `<fill or "unknown">` | TODO | TODO |
| TODO | TODO | TODO | TODO | TODO |

## 4. Notify-registration dependencies

*What must be registered with Adobe at onboarding, or configured on the partner
side, before the Notify flow can be validated end-to-end (registered auth type,
credential/config source, endpoint URL). Blocks go-live until resolved. Keep
consistent with the Notify strategy in [`../shared/OFFER_PROFILE.md`](../shared/OFFER_PROFILE.md).*

| Dependency | Owner | Status | Blocks |
|---|---|---|---|
| `<fill: e.g. registered inbound-auth type>` | `<fill: partner/Adobe>` | `<fill: pending/done>` — TODO | `<fill>` |
| TODO | TODO | TODO | TODO |
