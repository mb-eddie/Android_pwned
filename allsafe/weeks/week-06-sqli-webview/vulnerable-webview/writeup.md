# <Vulnerability Name>

| | |
|---|---|
| **App** | Allsafe vX.X |
| **Week** | XX |
| **Category** | e.g. Insecure Logging |
| **MASVS** | MASVS-XXXX |
| **MASTG** | MASTG-TEST-XXXX |
| **Severity** | Low / Medium / High / Critical (with reasoning) |
| **Android / device** | e.g. Android 13 AVD, rooted |
| **Tool versions** | frida X.X, jadx X.X, ... |

## 1. Summary
Two or three sentences: what is broken and what an attacker gets.

## 2. Background
Short explanation of the vulnerability class for readers new to it.

## 3. Recon
What the feature does. Relevant manifest entries, permissions, exported components.

## 4. Static Analysis
Decompile steps, the vulnerable code snippet, and why it is vulnerable.

```java
// vulnerable code
```

## 5. Dynamic Analysis
Runtime confirmation (logcat, Frida, Burp, etc.).

## 6. Exploitation
Numbered, reproducible steps.

1. ...
2. ...

### Proof of Concept
```bash
# commands / script
```
Artifacts: [`artifacts/`](artifacts/)

📸 Evidence: `evidence/`

## 7. Impact
Realistic scenario in a production app. Who is affected, what is exposed.

## 8. Remediation
```java
// secure version
```
- Primary fix
- Defence in depth
- How to verify the fix

## 9. Detection / Testing Notes
How would a pentester or SAST/DAST tool find this in a real engagement?

## 10. References
- OWASP MASTG:
- Allsafe:
- Other:
