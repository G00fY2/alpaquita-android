# Contributing to this Project

Thank you for your interest in contributing! Since I maintain this Docker project alone in my free time, I appreciate your help, but I also ask you to follow these simple guidelines to keep the image secure, fast, and maintainable.

---

## AI Usage Policy

I welcome AI as a productive tool, but I want to avoid unverified "KI-Slop" (low-effort, untested code). Therefore, the rules are simple:

- **Disclose AI usage:** If you used tools like GitHub Copilot, ChatGPT, or Claude, please state it in your Pull Request, along with the extent to which it helped you.
- **Understand your code:** You must fully understand every line of code or configuration (Dockerfiles, Compose files, entrypoint scripts) you submit. If you can't explain it without an AI, please do not submit it.
- **Security & Best Practices:** AI tools often suggest insecure defaults, outdated base images, or hardcoded credentials. You are 100% responsible for ensuring your submission follows modern Docker security practices.
- **Review and edit text:** If you use AI to write descriptions or issues, review and trim them. AI tends to be overly verbose. Low-effort spam or purely AI-generated text will be closed immediately.

---

## Linting & Code Quality

Before opening a Pull Request, your changes **must** pass our local linters and formatters. Contributions that fail these checks will be automatically rejected. Please ensure you adhere to the following standards:

* **Dockerfiles (`hadolint` & `dive`):** Must comply with `hadolint` best practices (e.g., pin base images with SHA-256 digests, use `set -o pipefail` in `RUN` layers, sort multi-line arguments alphanumerically, and use JSON/Exec form for `ENTRYPOINT`/`CMD`). Every build is also analyzed by `dive` for layer efficiency.
* **Shell Scripts (`shellcheck` & `shfmt`):**
  * Use `#!/bin/sh` with `set -eu` for POSIX scripts.
  * Use `#!/usr/bin/env bash` with `set -euo pipefail` for Bash scripts.
  * All scripts must pass `shellcheck` and be formatted using `shfmt`.
* **YAML Files (`yamllint`):** All GitHub Actions workflows and YAML configurations must pass `yamllint` using our project's configuration.
* **Code Style:** Coding language is strictly **English**. Follow our `.editorconfig` for formatting, naming conventions, and line endings.

### Key Technical Rule for Docker Changes:
This image runs in restricted Kubernetes environments. Any directory or cache path you add **must follow the GID 0 strategy** (owned by root group `chgrp -R 0` with `chmod -R g=u`) and support arbitrary UIDs (`runAsNonRoot: true`).

---

## How to Contribute

### 1. I found a bug or have a feature idea
* **Search first:** Please check existing Issues and Discussions to see if your topic was already covered.
* **Open a Discussion:** If it's a new bug or idea, please open a thread in **GitHub Discussions** first. This keeps the Issue tracker clean.

### 2. I want to submit code (Pull Requests)
* **Link to an issue/discussion:** Please don't open "surprise" Pull Requests for major changes without discussing them first.
* **Keep it clean:** Ensure your Docker configurations are tested, build properly, and don't introduce unnecessary complexity.

---

## Project Workflow

* **GitHub Discussions:** The place for ideas, general questions, and bug triaging.
* **GitHub Issues:** Only used for *actionable* tasks that are confirmed and ready to be worked on.

Thank you for respecting my time and helping me keep this project secure and maintainable!
