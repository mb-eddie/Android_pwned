# Weekly Publishing Checklist

## Before publishing
- [ ] Exploit reproduced on a clean AVD snapshot
- [ ] Commands copy-paste tested
- [ ] Artifacts committed (scripts, payloads, patches)
- [ ] Screenshots/recordings added to `evidence/`
- [ ] Secrets, IPs, tokens, serials redacted
- [ ] No APKs or keystores in the commit
- [ ] Remediation section includes secure code
- [ ] MASVS mapping filled
- [ ] Root README tracker updated

## Publishing
- [ ] Push to GitHub
- [ ] LinkedIn post (use `templates/linkedin-post-template.md`)
- [ ] Medium article (use `templates/medium-article-template.md`)
- [ ] Add links back into the README tracker
- [ ] Tag the week: `git tag week-XX && git push --tags`

## Suggested rhythm
| Day | Task |
|---|---|
| Mon | Recon + static analysis, both vulns |
| Tue | Dynamic analysis + exploitation |
| Wed | Artifacts, evidence, write-ups |
| Thu | Push to GitHub, LinkedIn post (vuln 1) |
| Sat | LinkedIn post (vuln 2) + Medium recap |
