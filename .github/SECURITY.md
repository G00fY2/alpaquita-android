# Security Policy

I take the security of this Docker image seriously. As a standalone maintainer, I rely on automated tooling alongside community vigilance to keep this project secure.

## Automated Security Scanning

This repository uses automated security analysis to catch vulnerabilities before they reach production:

* **CodeQL:** GitHub’s static analysis tool runs on every push and pull request to detect code-level security flaws.
* **Trivy:** The image is continuously scanned for vulnerabilities during the CI build process.

> [!NOTE]
> **Alpaquita OS Support:** Please note that Trivy does not currently support OS-level vulnerability scanning for Alpaquita. While Trivy still scans the image's packages and dependencies, OS-level vulnerabilities cannot be fully detected via Trivy at this time.

### Viewing Vulnerability Reports
* **GitHub Actions:** Detailed Trivy scan results can be found in the logs of the respective workflow runs.
* **Exceptions:** Intentionally ignored vulnerabilities or false positives are explicitly documented and managed via the `trivyignore.yaml` file in the repository root.

## Reporting a Vulnerability

If you find a security vulnerability, please **do not open a public issue**. Instead, report it privately so I can address it without putting environments at risk.

Please report security issues via email to: twirth.development@gmail.com

**Please include the following in your report:**
* A description of the vulnerability and its potential impact.
* Steps to reproduce or a proof of concept (PoC).
* Any specific packages, tools, or layers involved.

Thank you for helping keep this project secure!
