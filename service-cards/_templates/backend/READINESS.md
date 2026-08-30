# Readiness — {service_name}

*Per-integration-point readiness for this backend surface. Each row gets a
status, the file path that evidences it, and a note. The verify step updates
this card after running the [`BUILD_CONFIG.md`](./BUILD_CONFIG.md) commands.
Follows [`../../../manual/methodology/card-model.md`](../../../manual/methodology/card-model.md) §4.3 and feeds
the reporting in [`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md).*

---

## Legend

| Status | Meaning |
|---|---|
| ✅ | Present and verified — evidence cited, builds/tests pass for this point. |
| ⚠️ | Partial / best-effort — exists but unverified, incomplete, or assumptions made. |
| ❌ | Absent — not yet implemented. |

## Status

*Fill Status with ✅/⚠️/❌, Evidence with a real file path (or `—` when absent),
and Notes with what is missing or what was verified.*

| Integration point | Status | Evidence (file path) | Notes |
|---|---|---|---|
| IMS client | ❌ | `<fill or —>` | TODO |
| Retail API client | ❌ | `<fill or —>` | TODO |
| Claim flow | ❌ | `<fill or —>` | TODO |
| Subscription (find) flow | ❌ | `<fill or —>` | TODO |
| Cancel flow | ❌ | `<fill or —>` | TODO |
| Notify | ❌ | `<fill or —>` | TODO |
| Testing | ❌ | `<fill or —>` | TODO |
| Configuration | ❌ | `<fill or —>` | TODO |
| Stack confidence | ⚠️ | `<fill or —>` | TODO: validated vs best-effort |
