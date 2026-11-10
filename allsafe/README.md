# Allsafe Native Android Track

This directory contains the native Android application security series for [Allsafe](https://github.com/t0thkr1s/allsafe), an intentionally vulnerable training app.

## Contents

- [`weeks/`](weeks/) — canonical weekly write-ups, artifacts, and evidence
- [`docs/`](docs/) — lab setup, methodology, checklist, and command reference
- [`templates/`](templates/) — write-up and publishing templates
- [`scripts/`](scripts/) — helpers for creating weekly folders

The repository-level progress tracker is in [`../README.md`](../README.md). Download the target APK only from the [upstream releases](https://github.com/t0thkr1s/allsafe/releases); APKs and decompiled application copies are not stored here.

## Week 1

The [hardcoded-credentials write-up](weeks/week-01-logging-hardcoded-creds/hardcoded-credentials/writeup.md) documents JADX and Apktool analysis, the `regbait` scan results, manual search workflow, and the evidence captured in the lab. Scanner results are documented as leads and raw credential/key values are redacted.
