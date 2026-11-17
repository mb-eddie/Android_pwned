# Security Assessment Report: Firebase Realtime Database Exposure

| Field | Details |
|---|---|
| **Report ID** | ANDROID-ALLSAFE-W02-03 |
| **Assessment** | Week 2, Day 3 — Allsafe Firebase Database challenge |
| **Finding** | Unauthenticated read access to Firebase Realtime Database |
| **Severity** | Medium — CVSS v3.1: 5.3 |
| **CVSS vector** | `AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N` |
| **Status** | Confirmed in the intentionally vulnerable lab |
| **Assessment date** | Not recorded |
| **Affected component** | Allsafe challenge Firebase Realtime Database |

## 1. Executive Summary

The Allsafe Android application contains the configuration needed to locate its Firebase Realtime Database. During authorized testing of the challenge environment, a read-only request made without authentication returned challenge data. This demonstrates that the database's effective access policy permits unauthenticated reads.

The observed records were challenge data; no real user information was identified. Write access was not tested. The finding is rated Medium based on the limited confidentiality impact observed. Reassess severity if the same policy protects sensitive production data.

## 2. Scope and Method

Testing was limited to the deliberately vulnerable Allsafe challenge application and its associated training database. Static analysis used JADX/apktool and the `regbait` scanner on the local APK. Dynamic validation was read-only. No write, deletion, enumeration beyond the challenge root, or testing of unrelated Firebase projects was performed.

## 3. Technical Finding

### Description

The APK includes a Firebase Realtime Database URL in its resources. A client-side database URL is not a credential; access control must be enforced by Firebase Security Rules. In the authorized challenge environment, the effective rules allowed an unauthenticated client to read challenge records from the database root.

### Evidence

Static inspection located the `firebase_database_url` resource. An unauthenticated, read-only check against the in-scope challenge database returned challenge-specific content. The target hostname and returned values are omitted from this report.

Companion screenshots are stored under `allsafe/weeks/week-02-firebase-database-shared-preferences/firebase-database/evidence/`:

| Evidence | Description |
|---|---|
| `1.challenge_access.png` | Challenge entry point |
| `2.challenge_description.png` | Challenge briefing |
| `3.challenge_interaction.png` | In-app challenge interaction |
| `4.firebase_string_search.png` | Firebase resource discovered during static analysis |
| `5.regbait_customtool_results.png` | Local scanner output |
| `6.getting_flag.png` | Challenge response confirmation; values intentionally not reproduced here |

### Reproduction Summary

1. Obtain and run the Allsafe challenge APK in an authorized, isolated lab.
2. Decompile the APK and inspect its resources for the Firebase database configuration.
3. In the challenge environment only, verify whether a read-only request without an authenticated user is accepted.
4. Record only the minimum challenge data needed to confirm the issue. Do not attempt writes or test unrelated projects.

The database address and response are intentionally redacted to avoid directing requests at a live endpoint.

### Root Cause

The Firebase Realtime Database rules do not require authentication and authorization for the affected read path. Obscuring the database URL in an APK would not fix this issue; the endpoint is discoverable by design and the server-side rules must enforce access.

## 4. Impact

An unauthenticated party able to reach the database can read data covered by the permissive rule. In a production deployment, that could expose user or business records, depending on the data stored and the rule's scope. This assessment confirmed exposure of challenge data only; it did not establish exposure of real user records or write access.

### Severity Rationale

CVSS v3.1 is scored at **5.3 (Medium)** using low confidentiality impact because only low-sensitivity challenge data was observed: `AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N`. Integrity and availability impact are not included because they were not tested. Recalculate the score if production data classification or rule scope indicates greater impact.

## 5. Remediation

1. **Deny access by default.** Require Firebase Authentication for non-public data and apply per-record authorization, such as checking that the authenticated UID matches the record owner.
2. **Limit public access deliberately.** If a dataset must be public, scope read access to only that dataset and keep writes denied unless a documented use case requires them.
3. **Test rules before release.** Add Firebase Emulator Suite tests proving unauthenticated reads and writes are rejected and authenticated users cannot access another user's records.
4. **Use App Check as defense in depth.** App Check can reduce requests from unauthorized clients but does not replace Security Rules or user authorization.
5. **Review embedded values separately.** The local static scan also reported other resource-level values. Their values are omitted; validate each finding independently, restrict client API keys, and rotate any credential that grants access.

## 6. Verification Criteria

- Unauthenticated reads and writes to protected paths are rejected.
- Authenticated users can access only the records permitted by the rules.
- Emulator-based rules tests pass in CI before deployment.
- The production rule set is reviewed and monitored for unexpected access patterns.

## 7. Standards Mapping

- **OWASP MASVS-AUTH:** authorization is enforced for data access.
- **OWASP MASVS-NETWORK:** backend communications use secure transport; transport encryption does not replace authorization.
- **OWASP MASVS-STORAGE:** sensitive data is not exposed through improperly protected backend storage.

## 8. Limitations

This report documents a training challenge, not an assessment of a production service. The assessment did not test write permissions, other database paths, production datasets, or the separate scanner findings. No conclusion about real-user data exposure should be inferred from the challenge result.
