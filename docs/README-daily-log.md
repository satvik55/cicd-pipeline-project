# AutoDeploy API — Development Journal

**Demo:** https://asciinema.org/a/RQMJtfTY4HifCGZY

## Project Overview

End-to-end CI/CD pipeline that automatically builds, tests, scans, and deploys a Node.js REST API to AWS EC2 using industry-standard DevOps tools.

## Final Outcome (What This Project Proves)

- Fully automated CI/CD: code → production in ~3–5 minutes
- Zero manual deployment (100% pipeline-driven)
- Infrastructure recreated from scratch in ~25 minutes (Terraform)
- Security enforced via Trivy (blocks vulnerable builds)
- Successfully tested with 5+ consecutive pipeline runs
- Production-ready system with auto-recovery, logging, and monitoring

**Pipeline Flow:**
```
Push to GitHub → Jenkins triggers → Tests → Trivy scan
→ Docker build → DockerHub push → Ansible deploy → Live on EC2 behind Nginx
```

**Live DockerHub Image:** [satvik55/cicd-api](https://hub.docker.com/r/satvik55/cicd-api)
> Note: Docker image name retained as `cicd-api` for compatibility.
---

## Key Features

- Fully automated CI/CD pipeline triggered on every `git push`
- Dockerized Node.js API with multi-stage build (~120MB production image)
- AWS infrastructure provisioned entirely with Terraform (IaC)
- Secure deployment via Ansible over SSH
- Container vulnerability scanning with Trivy (DevSecOps)
- Production-hardened Jenkins with JVM tuning, swap, and disk cleanup
- Optimized for low-cost AWS instances (t3.small Jenkins, t3.micro App)

---

## Architecture

```
┌──────────────────────── AWS VPC (10.0.0.0/16) ────────────────────────┐
│                                                                        │
│  ┌── Public Subnet 1 (10.0.1.0/24) ──┐  ┌── Public Subnet 2 (10.0.2.0/24) ──┐
│  │                                     │  │                                     │
│  │  ┌───────────────────────────────┐  │  │  ┌───────────────────────────────┐  │
│  │  │ Jenkins Server (t3.small)     │  │  │  │ App Server (t3.micro)         │  │
│  │  │ • Jenkins CI/CD (port 8080)   │  │  │  │ • Docker container (port 3000)│  │
│  │  │ • Docker builds & pushes      │──┼──┼──│ • Nginx reverse proxy (:80)   │  │
│  │  │ • Trivy scanning              │  │  │  │ • Managed by Ansible          │  │
│  │  │ • Ansible controller          │  │  │  │                               │  │
│  │  └───────────────────────────────┘  │  │  └───────────────────────────────┘  │
│  └─────────────────────────────────────┘  └─────────────────────────────────────┘
│                                                                        │
│                          Internet Gateway                              │
└────────────────────────────────┬───────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │       Internet           │
                    │  • GitHub (webhook)      │
                    │  • DockerHub (registry)  │
                    └─────────────────────────┘
```

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Node.js | REST API (Express.js) |
| Docker | Containerization (multi-stage build) |
| Jenkins | CI/CD automation server |
| Terraform | Infrastructure as Code (AWS provisioning) |
| Ansible | Configuration management & deployment |
| Nginx | Reverse proxy (port 80 → 3000) |
| Trivy | Container vulnerability scanning (DevSecOps) |
| AWS | EC2, VPC, Security Groups, IAM |
| GitHub | Version control + webhook triggers |

---

## Daily Progress

### Day 1 — Environment Setup & Project Structure

**Built:** Installed all tools (Docker, Terraform, Ansible, AWS CLI, Trivy, Node.js) on Mac M1. Configured AWS CLI for ap-south-1. Created EC2 key pair. Initialized GitHub repo with project folder structure.

**Tools:** Homebrew, Git, AWS CLI, Docker, Terraform, Ansible, Trivy

**Outcome:** Development environment fully configured and AWS-ready.

---

### Day 2 — Node.js REST API

**Built:** Express.js REST API with CRUD endpoints, `/health` endpoint for monitoring, input validation, proper HTTP status codes, graceful shutdown (SIGTERM/SIGINT). Wrote 14 Jest + Supertest tests covering all routes.

**Tools:** Node.js, Express.js, Jest, Supertest

**Outcome:** Production-ready API with 90%+ test coverage.

---

### Day 3 — Docker & DockerHub

**Built:** Multi-stage Dockerfile — Stage 1 runs tests (build gate), Stage 2 produces ~120MB production image with non-root user. Docker Compose for local dev. Cross-platform build via Buildx (linux/amd64 for EC2).

**Tools:** Docker, Docker Compose, Buildx, DockerHub

**Outcome:** Containerized app pushed to [satvik55/cicd-api](https://hub.docker.com/r/satvik55/cicd-api) with versioned tags.

---

### Day 4 — Terraform & AWS Infrastructure

**Built:** Complete AWS infrastructure as modular Terraform code — VPC (10.0.0.0/16), 2 public subnets, Internet Gateway, route tables, Security Groups (Jenkins: 22/8080, App: 22/80/443 + cross-SG SSH), 2 EC2 instances, IAM role with SSM, encrypted gp3 EBS volumes.

**Tools:** Terraform, AWS (EC2, VPC, IAM, Security Groups)

**Outcome:** Fully reproducible infrastructure. `terraform apply` = create, `terraform destroy` = teardown. Zero console clicks.

---

### Day 5 — Jenkins Installation & Configuration

**Built:** Installed Jenkins, Java 17, Docker, Trivy, Ansible, Git on Jenkins EC2. Created pipeline job connected to GitHub repo via SCM. Configured credentials (DockerHub, GitHub PAT, EC2 SSH key). Verified Jenkins→App SSH connectivity for Ansible deployments.

**Tools:** Jenkins, Java 17, Docker, Trivy, Ansible, Git, AWS EC2

**Outcome:** Jenkins operational on port 8080 with all plugins, credentials, and pipeline job ready.

---

### Day 6 — Jenkinsfile CI/CD Pipeline + GitHub Webhook

**Built:** Declarative Jenkins pipeline with 7 stages: Checkout → Install Dependencies → Run Tests → Docker Build → Trivy Security Scan → Docker Push → Deploy (placeholder). GitHub webhook triggers pipeline on every push. Docker images tagged with `BUILD_NUMBER-GIT_SHA` for traceability. Created `jenkins_setup.sh` for automated server provisioning.

**Challenges Resolved:**
- Docker build OOM on t3.micro → upgraded to t3.small, added 2GB swap, capped JVM to 512MB
- Disk pressure from images → added `docker image prune` + `cleanWs()` in post block
- npm memory spikes → limited with `--maxsockets=2`
- Permission errors → fixed with `chown` and Docker group membership

**Tools:** Jenkins, Declarative Pipeline, Docker Pipeline plugin, Trivy, GitHub Webhooks

**Outcome:** Every `git push` auto-triggers: test → scan → build → push to DockerHub. Pipeline stable at ~4 min.

---

### Day 7 — Week 1 Review & Production Hardening

**Built:** Locked all operational fixes into version-controlled code. Updated Terraform with separate instance types (Jenkins=t3.small, App=t3.micro). Updated `jenkins_setup.sh` with JVM limits, persistent swap, and all dependency installs. Optimized Jenkinsfile with workspace cleanup and reduced log retention.

**Tools:** Terraform, Jenkins (systemd tuning), Docker, Linux (swap, fstab, systemd overrides)

**Outcome:** Entire project is reproducible from scratch — Terraform provisions infra, setup script configures Jenkins, Jenkinsfile runs the pipeline. Key lesson: t3.micro is insufficient for CI/CD workloads.

#### Week 1 Summary

| Day | Milestone |
|-----|-----------|
| 1 | Tools + AWS CLI + project structure |
| 2 | Node.js REST API — 14 passing tests |
| 3 | Docker multi-stage build → DockerHub |
| 4 | Terraform: VPC, EC2, Security Groups, IAM |
| 5 | Jenkins installed + configured on EC2 |
| 6 | Jenkinsfile pipeline + GitHub webhook |
| 7 | Production hardening — t3.small, swap, JVM caps |

---

## Project Status

- [x] Day 1: Environment setup & project structure
- [x] Day 2: Node.js REST API with tests
- [x] Day 3: Docker & DockerHub
- [x] Day 4: Terraform AWS infrastructure
- [x] Day 5: Jenkins installation & configuration
- [x] Day 6: CI/CD pipeline + GitHub webhook
- [x] Day 7: Week 1 review & hardening
- [x] Day 8: Elastic IPs + Ansible deployment
- [x] Day 9: Jenkins → Ansible auto deployment
- [x] Day 10: Full pipeline integration (Jenkins → Ansible → App)
- [x] Day 11: Strict Trivy scanning + DevSecOps + image retention
- [x] Day 12: Bash utility scripts (health check, cleanup)
- [x] Day 13: Final fixes + edge cases + pipeline polish
- [x] Day 14: Week 2 review & final cleanup
- [ ] Day 15–21: Documentation, diagrams, resume polish

---

## Quick Start

```bash
# Clone and run locally
git clone https://github.com/satvik55/autodeploy-api.git
cd autodeploy-api/app
npm install && npm test && npm start

# Docker
docker build -t cicd-api -f docker/Dockerfile .
docker run -p 3000:3000 cicd-api

# Terraform (provision AWS infra)
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit with your values
terraform init && terraform apply

# Teardown
terraform destroy
```

---

## Cost Management

| Resource | Type | Cost |
|----------|------|------|
| App Server | t3.micro | Free Tier (750 hrs/month) |
| Jenkins Server | t3.small | ~₹1.4/hour (stop when not in use) |
| EBS Volumes | gp3, 20GB + 15GB | Free Tier (30GB included) |

**Always run `terraform destroy` or stop instances when done working.**

Billing dashboard: https://console.aws.amazon.com/billing/

---

## License

MIT
---

## Day 8 — Elastic IPs + Ansible Deployment

**Built:**
Allocated Elastic IPs via Terraform to eliminate the IP-change problem on stop/start (no more manual Jenkins URL or webhook fixes). Wrote 3 Ansible roles: docker (install Docker on app server), app-deploy (pull image from DockerHub, run container with health check), nginx (reverse proxy from port 80 to container port 3000). Created main playbook that orchestrates all roles. App now accessible at `[http://APP_IP](http://3.111.228.220)` through Nginx. Set up Ansible on Jenkins server for pipeline-triggered deployments.

**Tools:**
Terraform (Elastic IPs), Ansible (roles, playbooks, inventory), Nginx, Docker

**Challenges & Fixes:**
- Faced repeated Nginx failures due to incorrect `proxy_pass` syntax caused by Jinja2 template parsing → replaced template module with `copy` to preserve raw config.
- Jenkins could not connect to App server via Ansible → resolved by updating Security Group to allow SSH within VPC (10.0.0.0/16).
- SSH key not available for Jenkins user → securely transferred key and fixed permissions (`chmod 400`, correct ownership).
- Ansible inventory misconfiguration (`ansible_host` used incorrectly) → corrected format with proper host alias.
- Jenkins initially used public IP causing connection timeout → switched to private IP for internal VPC communication.
- Environment variables ($JENKINS_IP, $APP_IP) not persisting → identified session-based behavior and re-exported when needed.

**Outcome:**
App fully deployed and live behind Nginx reverse proxy on EC2. Ansible deployment runs from both local Mac and Jenkins server. Elastic IPs ensure stable infrastructure across stop/start cycles. Internal VPC communication established for secure and efficient deployment.


---

## Day 9 — Full End-to-End Pipeline: Jenkins → Ansible → Live App

**Built:**
Wired Ansible into Jenkins pipeline for automated deployment. Created deploy.yml playbook to pull latest Docker image, restart container, and verify health. Added Deploy and Health Check stages in Jenkinsfile. Configured Ansible setup on Jenkins server at /opt/ansible. Pipeline now runs 8 stages from code commit to live deployment.

**Tools:**
Jenkins (Pipeline), Ansible, Docker, Nginx, Trivy

**Challenges & Fixes:**
- Jenkins pipeline failed due to Groovy `$` parsing error → fixed by escaping variables (`\$` and `\${}`).
- Health Check stage initially failed due to incorrect shell command parsing → corrected grep/awk syntax.
- Jenkins unable to SSH via public IP → switched to private IP for secure VPC communication.
- Security Group rules not allowing internal traffic → updated to allow VPC CIDR (10.0.0.0/16).
- App health check confusion (port 3000 vs Nginx 80) → verified correct endpoint and routing.

**Outcome:**
Fully automated CI/CD pipeline achieved. Every `git push` triggers build, scan, Docker push, Ansible deployment, and health verification. Application deployed behind Nginx reverse proxy and accessible via public IP with zero manual intervention.


---

## Day 10 — Integration Testing + Pipeline Hardening

**Built:**
Ran 4+ full end-to-end pipeline executions to verify reliability. Added Post-Deploy Verify stage that confirms the app responds through Nginx after deployment. Improved deploy.sh with SSH pre-check, Docker cleanup on target server, and better error handling. Created utility scripts: health_check.sh, cleanup_images.sh, backup_config.sh. Made small code changes and verified each triggered a full pipeline cycle with new Docker image tags on DockerHub.

**Tools:**
Jenkins (8-stage pipeline), Docker (image tagging), Bash (utility scripts), Nginx (post-deploy verification)

**Outcome:**
Pipeline runs reliably across multiple executions. Each build produces a uniquely tagged Docker image (BUILD_NUMBER-GIT_SHA). Post-deploy verification confirms full stack health (app + Nginx). Utility scripts ready for operational use.

---

## Day 11 — Strict Trivy Scanning + DevSecOps + Image Retention

**Built:**
Implemented a strict DevSecOps security gate using Trivy, ensuring the CI/CD pipeline fails immediately if CRITICAL vulnerabilities are detected. Developed a custom `trivy_scan.sh` script to generate both console-friendly output and structured JSON reports. Integrated Jenkins artifact archiving to store scan reports for audit and compliance. Introduced `.trivyignore` to safely suppress verified base-image vulnerabilities. Built `image_retention.sh` to automatically retain only the latest 3 Docker images on the application server, preventing disk space issues.

**Tools:**
Trivy (strict scanning), Jenkins (artifact archiving), Docker, Bash scripting

**Challenges & Fixes:**

- **Pipeline failing due to CRITICAL vulnerabilities:**  
  Used Trivy reports to identify issues and added only verified base-image CVEs to `.trivyignore`, ensuring security without blocking deployments unnecessarily.

- **Trivy reports not visible in Jenkins:**  
  Fixed by configuring `archiveArtifacts` to store `trivy-report.json` and `trivy-summary.txt`.

- **Incorrect Docker image used during deployment:**  
  Resolved parameter mismatch in `deploy.sh` where server IP was mistakenly treated as image tag instead of build tag.

- **SSH failures from Jenkins to App server:**  
  Fixed by correcting SSH key permissions (`chmod 400`) and ensuring correct key path in pipeline.

- **Deployment script failures (invalid image format):**  
  Corrected variable passing inside SSH heredoc and ensured proper tag usage.

- **Shell syntax errors in remote execution:**  
  Fixed loop syntax and variable escaping inside deployment script.

- **Docker images accumulating on server (disk risk):**  
  Solved by implementing automated image retention logic to keep only latest 3 images.

**Outcome:**
Established a production-grade DevSecOps pipeline with enforced security validation, automated vulnerability reporting, and optimized Docker image lifecycle management. Only secure builds are deployed, ensuring reliability, auditability, and efficient resource usage.

---
---

## Pipeline Reliability

This pipeline has been tested with 5+ consecutive runs including:
- Normal code changes (new endpoints, version bumps)
- Intentional test failures (verified pipeline stops broken code)
- Documentation-only changes
- Manual triggers

All runs completed successfully with proper image tagging and deployment.

---

## Day 12 — 5 Pipeline Runs + Reliability Testing

**Built:**
Ran 5 full end-to-end pipeline executions: baseline run, new /info endpoint with test, intentional test failure (verified CI catches it), README-only change, and manual trigger. Added /info endpoint exposing system details (Node version, memory, uptime). Created pipeline-test-log.md documenting all test runs and results. All successful runs completed 8 stages in ~5 minutes each.

**Tools:**
Jenkins (8-stage pipeline), Jest (15 tests), Docker, Trivy, Nginx

**Outcome:**
Pipeline proven stable across 5 consecutive runs with different trigger types and code changes. CI correctly blocks broken code. Every build produces a uniquely tagged, scanned Docker image deployed automatically to production.

**Challenges & Fixes:**

- **Incorrect Docker image tag used during deployment:**  
  Pipeline failed because the App server attempted to pull `satvik55/cicd-api:3.111.228.220`, treating the server IP as the image tag.  
  **Cause:** Jenkinsfile passed 3 arguments (IP, TAG, KEY) to `deploy.sh`, but the script was designed to accept only the image tag.  
  **Fix:** Updated Jenkinsfile to pass only `${IMAGE_TAG}`, ensuring correct image version is deployed.

- **Pipeline verification failing after instance restart:**  
  Health check initially returned no response due to container not running after EC2 restart.  
  **Fix:** Relied on pipeline deployment stage to redeploy container automatically and added retry logic in Post-Deploy Verify.

- **Difficulty capturing consistent verification outputs for screenshots:**  
  Outputs were inconsistent due to pipeline timing and deployment delays.  
  **Fix:** Standardized verification commands and ensured execution after successful pipeline completion.
---

## Day 13 — Final Fixes + Edge Cases + Pipeline Polish

**Built:**
Added container auto-recovery (Docker enabled on boot, restart policy: unless-stopped) so the app survives EC2 reboots. Added container log rotation (10MB max, 3 files) to prevent disk fill. Created build_summary.sh for clean pipeline output with all relevant links. Updated Ansible app-deploy role with log limits and Docker auto-start. Finalized production-ready Jenkinsfile. Ensured all scripts are executable.

**Tools:**
Docker (restart policy, log rotation), Ansible (systemd enable), Bash (build_summary.sh), Jenkins

**Challenges & Fixes:**

- **Deploy script using wrong Docker image tag:**
  Pipeline failed at deploy stage with `docker.io/satvik55/cicd-api:3.111.228.220: not found`. Jenkins called `deploy.sh` with 3 arguments (IP, TAG, KEY) but the script only expected 1 argument (TAG), so `$1` picked up the server IP instead of the image tag.
  **Fix:** Added argument detection at the top of `deploy.sh` — if 3 args are passed, grab the tag from `$2` instead of `$1`.

- **`cleanWs()` deleting workspace before `build_summary.sh` runs:**
  Jenkins post block had `cleanWs()` inside `always`, which executes before `success`. By the time Jenkins tried to run `build_summary.sh`, the workspace was already wiped — causing `chmod: cannot access 'scripts/build_summary.sh': No such file or directory`.
  **Fix:** Moved `build_summary.sh` call and `cleanWs()` into a single `always` block with a file-existence check (`if [ -f scripts/build_summary.sh ]`), ensuring the script runs before cleanup.

- **Jenkinsfile changes not reaching Jenkins (uncommitted local changes):**
  Downloaded fixed Jenkinsfile was not placed in the project root, so `git add` had nothing to commit. Jenkins kept running the old broken version across multiple builds.
  **Fix:** Used `cat > Jenkinsfile << 'ENDOFFILE'` to write the file directly in terminal, then ran `git add -A && git commit && git push` to ensure changes reached Jenkins.

**Outcome:**
Pipeline is fully production-hardened. App auto-recovers from EC2 reboots. Container logs are bounded. Build output is clean and informative. Zero manual intervention needed for normal operations.

---

## Day 14 — Week 2 Review + Bug Fixes + Final Cleanup

**Built:**
Fixed 3 pipeline bugs: deploy.sh argument ordering (IP/TAG/KEY), Jenkinsfile post-block execution order (cleanWs must run after build_summary), and Jenkinsfile path (moved to repo root where Jenkins actually reads it). Cleaned project structure: removed stale files, verified all script permissions, updated .gitignore. Ran full system verification across all endpoints, infrastructure, and container config.

**Tools:**
Jenkins (pipeline config), Bash (deploy.sh fix), Git (repo cleanup)

**Challenges & Fixes:**

- **deploy.sh SSHing to public IP instead of private IP:**
  The Day 14 guide rewrote deploy.sh to use `$1` (public IP) for SSH, but Jenkins connects to the app server via VPC private IP. SSH timed out with `ERROR: Cannot SSH to 3.111.228.220`.
  **Fix:** Restored the private IP lookup from ansible inventory (`grep ansible_host /opt/ansible/inventory.ini`) so Jenkins SSHs internally within the VPC.

- **Jenkinsfile `${currentBuild.result}` inside single quotes:**
  The guide's Jenkinsfile used `${currentBuild.result}` and `${BUILD_NUMBER}` inside a `sh '''...'''` block (single quotes). Shell cannot expand Groovy variables in single quotes, causing `Bad substitution` error.
  **Fix:** Simplified the post block to call `scripts/build_summary.sh || true` without passing Groovy variables, keeping everything in plain shell.

- **Stale files in repo:**
  Found junk files: `README.md\` (backslash artifact), `docker/.dockerignore` (duplicate), `docker/.trivyignorey` (typo), `.DS_Store` files scattered everywhere, and `backups/` directory.
  **Fix:** Deleted all stale files and updated `.gitignore` to prevent them from returning.

**Outcome:**
Pipeline fully debugged and stable. All 8 stages pass reliably. Repo is clean and recruiter-ready.

### Week 2 Summary

| Day | Milestone |
|-----|-----------|
| 8 | Elastic IPs + Ansible roles (docker, app-deploy, nginx) |
| 9 | Full deploy pipeline + Nginx reverse proxy fix |
| 10 | 4 pipeline runs + Post-Deploy Verify stage |
| 11 | Strict Trivy scanning + DevSecOps security gate |
| 12 | 5 pipeline runs — reliability proven across trigger types |
| 13 | Auto-recovery, log rotation, build summary |
| 14 | 3 bug fixes, repo cleanup, full verification |

### Complete Pipeline (Final)
```
git push → GitHub Webhook → Jenkins (13.127.229.115:8080)
  ├─ 1. Checkout
  ├─ 2. Install Dependencies (npm ci --maxsockets=2)
  ├─ 3. Run Tests (15 Jest tests)
  ├─ 4. Docker Build (multi-stage, ~120MB)
  ├─ 5. Trivy Security Scan (strict: fails on CRITICAL CVEs)
  ├─ 6. Docker Push (satvik55/cicd-api:BUILD-SHA + latest)
  ├─ 7. Deploy to App Server (SSH → pull → restart → health check)
  └─ 8. Post-Deploy Verify (Nginx health check)
  
→ App live at http://3.111.228.220 behind Nginx
```

---

## Day 15 — Architecture Diagrams + Screenshots

**Built:**
Created architecture diagrams in Mermaid (renders natively on GitHub) and SVG (works everywhere). Collected key screenshots: Jenkins pipeline stages, Trivy scan output, running app, DockerHub tags, Terraform output, Ansible deployment. Organized all screenshots with an index file.

**Tools:**
Mermaid (GitHub-native diagrams), SVG, Jenkins, Browser

**Outcome:**
Project is visually documented with professional architecture diagrams and proof-of-work screenshots. All diagrams render directly in GitHub.

### Architecture Diagram

See full interactive diagrams: [docs/architecture.md](docs/architecture.md)

### Key Screenshots

| What | Description |
|------|------------|
| Pipeline Stages | All 8 Jenkins stages passing (green) |
| Trivy Scan | Security vulnerability scan results |
| Live App | Health endpoint responding at http://3.111.228.220 |
| DockerHub | Multiple tagged images (BUILD-SHA format) |
| Terraform | Infrastructure outputs with Elastic IPs |
| Ansible | Successful deployment playbook run |

---

## Day 16 — Comprehensive README Rewrite (Recruiter-Ready)

**Built:**
Replaced the entire daily-log README with a clean, professional README structured like a real open-source project. Covers architecture, tech stack, pipeline stages, project structure, quick start guide, DevSecOps practices, operational features, API endpoints, lessons learned, cost management, and resume bullet points. Old daily log preserved at docs/README-daily-log.md.

**Tools:**
Markdown, Git

**Challenges & Fixes:**

- **Code blocks breaking in heredoc:**
  The `cat > README.md << 'EOF'` approach corrupted triple-backtick code blocks — the shell interpreted them as nested heredoc terminators, causing raw markdown to appear on GitHub instead of formatted code.
  **Fix:** Created the README as a proper file using a file creation tool and copied it into the project, bypassing shell heredoc entirely.

**Outcome:**
README is now recruiter-ready. A hiring manager can understand the project scope, tech stack, and depth of work within 30 seconds.

---

## Day 17 — Terraform Destroy + Recreate: Prove It's Reproducible

**Built:**
Destroyed all 16 AWS resources with `terraform destroy`, then recreated everything from scratch with `terraform apply`. New Elastic IPs allocated. Rebuilt Jenkins server from `jenkins_setup.sh`. Deployed app via Ansible. Updated all hardcoded IPs across Jenkinsfile, README, architecture.md, SVG, build_summary.sh, and Ansible inventory. Pipeline passed all 8 stages on fresh infrastructure. Created docs/rebuild-checklist.md for future rebuilds.

**Tools:**
Terraform (destroy/apply), Jenkins (fresh setup), Ansible (full playbook), Bash (jenkins_setup.sh)

**Challenges & Fixes:**

- **Jenkins GPG key changed — package install failed:**
  `apt-get install jenkins` failed with `NO_PUBKEY 7198F4B714ABFC68`. Jenkins updated their signing key and the old `jenkins.io-2023.key` no longer works with the new keyring method.
  **Fix:** Imported the key directly from Ubuntu keyserver: `sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68`.

- **Node.js/npm not installed on fresh Jenkins server:**
  Pipeline failed at Stage 2 with `npm: not found`. The `jenkins_setup.sh` script failed partway through due to the GPG issue, so Node.js was never installed.
  **Fix:** Installed Node.js 18 separately: `curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs`.

- **New IPs required updates in 8+ files:**
  Elastic IPs change on destroy/apply. Every hardcoded IP in Jenkinsfile, README, architecture.md, SVG diagram, build_summary.sh, Ansible inventory, and GitHub webhook needed updating.
  **Fix:** Used `sed -i '' "s/OLD_IP/NEW_IP/g"` across all files, then verified with grep to confirm no stale IPs remain.

**Outcome:**
Infrastructure proven 100% reproducible. Full destroy → recreate → deploy → pipeline pass in ~25 minutes. This is the strongest interview proof point: "I destroyed everything and rebuilt it from my Git repo and Terraform code."

**New IPs after recreate:**
- Jenkins: 13.126.223.204
- App: 3.109.171.228
- App Private: 10.0.2.104

## Day 18 — Demo Recording + Final Polish

**Built:**
Recorded a terminal-based demo showcasing the complete project workflow — project structure, test execution, pipeline stages, and live API responses from AWS. Added demo recording to repository for easy playback.

Performed final cleanup: regenerated package-lock.json, fixed minor inconsistencies, verified all endpoints, and ensured zero stale references to old project name.

**Tools:**
asciinema, Node.js, Jenkins, AWS EC2

**Outcome:**
Project is fully polished, reproducible, and demo-ready. Recruiters can quickly understand the workflow through a real execution recording.