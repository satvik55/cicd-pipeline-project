# AutoDeploy API — One-Click Secure Deployment System on AWS

A deployment system that takes a Node.js API from code push to live production on AWS in under 5 minutes — builds, tests, scans for vulnerabilities, containerizes, and deploys automatically with zero manual steps.

**Live DockerHub Image:** [satvik55/cicd-api](https://hub.docker.com/r/satvik55/cicd-api)

**Demo:** [Watch terminal recording](https://asciinema.org/a/RQMJtfTY4HifCGZY)

## Pipeline Flow

```
git push → GitHub Webhook → Jenkins Pipeline
  → Checkout Code
  → Install Dependencies
  → Run 15 Jest Tests
  → Docker Build (multi-stage, ~120MB)
  → Trivy Security Scan (fails on CRITICAL CVEs)
  → Push to DockerHub (satvik55/cicd-api:BUILD-SHA)
  → SSH Deploy to EC2 (pull → restart → health check)
  → Post-Deploy Verify (Nginx health check)
  → App live at http://3.109.171.228
```

⚡ Full cycle completes in ~5 minutes. Failed tests or vulnerabilities stop deployment — ensuring only production-ready code goes live.
---

## Architecture

See interactive Mermaid diagrams: [docs/architecture.md](docs/architecture.md)

```
                         ┌─────────────┐
   Developer ──push──▶   │   GitHub    │
                         └──────┬──────┘
                                │ webhook
                                ▼
                    ┌───────────────────────┐
                    │   Jenkins Pipeline     │
                    │   13.126.223.204:8080  │
                    │                        │
                    │  1. Checkout           │
                    │  2. npm ci             │
                    │  3. Jest tests (15)    │
                    │  4. Docker build       │
                    │  5. Trivy scan ✗/✓     │
                    │  6. Docker push ──────────▶ DockerHub
                    │  7. SSH deploy ───┐    │   satvik55/cicd-api
                    │  8. Verify        │    │
                    └───────────────────┼────┘
                                        │ (VPC private IP)
                                        ▼
            ┌────────────────────────────────────────┐
            │  App Server (3.109.171.228)             │
            │  Private: 10.0.2.104                    │
            │                                         │
            │  Nginx :80 ──▶ Docker :3000 ──▶ API    │
            └────────────────────────────────────────┘
```

## AWS Infrastructure (Terraform)

All infrastructure provisioned with Terraform — zero manual console clicks.

```
┌──────────────────── VPC (10.0.0.0/16) ─────────────────────┐
│                                                              │
│  Subnet 1 (10.0.1.0/24)         Subnet 2 (10.0.2.0/24)    │
│  ┌────────────────────┐         ┌────────────────────┐      │
│  │ Jenkins Server      │   SSH   │ App Server          │     │
│  │ t3.small            │────────▶│ t3.micro            │     │
│  │ EIP: 13.126.223.204 │ (VPC)   │ EIP: 3.109.171.228  │     │
│  │ Port: 8080          │         │ Private: 10.0.2.104  │     │
│  └────────────────────┘         │ Port: 80 (Nginx)    │     │
│                                  └────────────────────┘      │
│                                                              │
│  Internet Gateway ──▶ Route Table ──▶ Both Subnets          │
└──────────────────────────────────────────────────────────────┘
```

| Resource | Details |
|----------|---------|
| VPC | 10.0.0.0/16 with DNS support |
| Subnets | 2 public across AZs (ap-south-1a, ap-south-1b) |
| EC2 | Jenkins (t3.small) + App (t3.micro) with Elastic IPs |
| Security Groups | Least-privilege: Jenkins (22/8080), App (22/80/443 + Jenkins SG) |
| IAM | EC2 role with SSM for emergency access |
| EBS | Encrypted gp3 volumes (20GB Jenkins, 15GB App) |

---

## Tech Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Application | Node.js, Express.js | REST API with CRUD + health check |
| Testing | Jest, Supertest | 15 automated tests |
| Containerization | Docker | Multi-stage build, non-root user, ~120MB |
| Registry | DockerHub | Image storage with BUILD-SHA tags |
| CI/CD | Jenkins | 8-stage declarative pipeline |
| Security | Trivy | Container vulnerability scanning (strict mode) |
| IaC | Terraform | VPC, EC2, SG, IAM, Elastic IPs — modular |
| Config Mgmt | Ansible | 3 roles: docker, app-deploy, nginx |
| Reverse Proxy | Nginx | Port 80 → container port 3000 |
| Cloud | AWS | EC2, VPC, Security Groups, IAM (ap-south-1) |
| Version Control | Git, GitHub | Webhooks for auto-triggered pipelines |

---

## Pipeline Stages

| # | Stage | What Happens | Fails If |
|---|-------|-------------|----------|
| 1 | Checkout | Pulls latest code from GitHub | Repo unreachable |
| 2 | Install Dependencies | `npm ci --maxsockets=2` | Package install fails |
| 3 | Run Tests | 15 Jest + Supertest tests | Any test fails |
| 4 | Docker Build | Multi-stage build (~120MB prod image) | Dockerfile errors |
| 5 | Trivy Security Scan | Scans for HIGH/CRITICAL CVEs | CRITICAL CVE found (strict) |
| 6 | Docker Push | Tags: BUILD_NUMBER-GIT_SHA + latest | Bad credentials |
| 7 | Deploy to App Server | SSH (VPC) → pull → stop → start → health check | SSH or health check fails |
| 8 | Post-Deploy Verify | Checks app through Nginx (port 80) | Nginx or container down |

---

## Project Structure

```
autodeploy-api/
├── Jenkinsfile                  # Pipeline definition (8 stages) — root level
├── app/
│   ├── src/
│   │   ├── app.js               # Express app (middleware, routes)
│   │   ├── index.js             # Server entry + graceful shutdown
│   │   ├── routes.js            # CRUD handlers + validation
│   │   └── info.js              # System info endpoint
│   ├── tests/
│   │   └── app.test.js          # 15 Jest tests
│   ├── package.json
│   └── jest.config.js
├── docker/
│   ├── Dockerfile               # Multi-stage (build + production)
│   └── docker-compose.yml
├── terraform/
│   ├── main.tf                  # Root module (wires vpc, ec2, sg)
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/
│       ├── ec2/
│       └── security-groups/
├── ansible/
│   ├── playbook.yml
│   ├── inventory.ini
│   ├── ansible.cfg
│   └── roles/
│       ├── docker/tasks/
│       ├── app-deploy/tasks/
│       └── nginx/tasks/ + templates/
├── scripts/
│   ├── deploy.sh                # SSH deploy (resolves private IP from inventory)
│   ├── trivy_scan.sh            # Scan + JSON reports
│   ├── jenkins_setup.sh         # Bootstrap Jenkins from scratch
│   ├── health_check.sh
│   ├── cleanup_images.sh
│   ├── image_retention.sh
│   ├── backup_config.sh
│   └── build_summary.sh
├── nginx/
│   └── nginx.conf
└── docs/
    ├── architecture.md          # Mermaid diagrams
    ├── pipeline-diagram.svg
    ├── pipeline-test-log.md
    ├── README-daily-log.md      # Day-by-day build journal
    └── screenshots/
```

---

## Quick Start

### Prerequisites

- macOS (Apple Silicon) or Linux
- AWS account with CLI configured
- Docker Desktop
- Terraform, Ansible installed

### 1. Clone and run locally

```bash
git clone https://github.com/satvik55/autodeploy-api.git
cd autodeploy-api/app
npm install
npm test          # 15 tests should pass
npm start         # http://localhost:3000/health
```

### 2. Docker build and run

```bash
docker build -t cicd-api -f docker/Dockerfile .
docker run -p 3000:3000 cicd-api
curl http://localhost:3000/health
```

### 3. Provision AWS infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform apply
```

### 4. Deploy with Ansible

```bash
cd ansible
ansible-playbook playbook.yml
```

### 5. Tear down

```bash
cd terraform && terraform destroy
```

---

## DevSecOps

- Trivy in **strict mode** — CRITICAL vulnerabilities block deployment
- Scan reports archived as Jenkins build artifacts (audit trail)
- `.trivyignore` for reviewed/accepted base-image CVEs
- Docker containers run as **non-root user** (`appuser`)
- EBS volumes **encrypted** (gp3)
- Security groups: **least-privilege** (SSH restricted to specific IPs)
- Jenkins→App deploy uses **VPC private IP** (never public for internal traffic)
- Secrets never committed (`.gitignore` covers .tfvars, .pem, .env)

---

## Operational Features

| Feature | Implementation |
|---------|---------------|
| Auto-recovery | `restart: unless-stopped` + Docker `systemctl enable` |
| Log rotation | Container logs capped at 10MB × 3 files |
| Disk cleanup | `docker image prune` per build + `image_retention.sh` |
| Elastic IPs | Static IPs survive stop/start — no URL updates |
| Health checks | `/health` endpoint + Nginx verify + deploy.sh retries |
| JVM tuning | Jenkins capped at 512MB via systemd override |
| Swap | 2GB persistent on Jenkins (via /etc/fstab) |
| npm optimization | `--maxsockets=2` prevents memory spikes |

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check (status, uptime, version) |
| GET | `/info` | System info (Node version, memory) |
| GET | `/` | API info + available endpoints |
| GET | `/api/projects` | List all projects |
| GET | `/api/projects/:id` | Get single project |
| POST | `/api/projects` | Create project |
| PUT | `/api/projects/:id` | Update project |
| DELETE | `/api/projects/:id` | Delete project |
| GET | `/nginx-health` | Nginx status |

---

## Lessons Learned

1. **t3.micro is not enough for CI/CD.** Docker builds + Jenkins + Trivy exceed 1GB RAM. t3.small + 2GB swap = stable.

2. **Elastic IPs save hours.** Without them, every stop/start means updating Jenkins URL, webhook, inventory, Jenkinsfile. With them: zero updates.

3. **Multi-stage Docker builds matter.** Builder: ~300MB. Production: ~120MB. Faster pulls, smaller attack surface.

4. **Separate app.js from index.js.** Tests import app without starting a server. Otherwise every test opens a port and they conflict.

5. **`cleanWs()` must run last in post block.** Use the `cleanup` directive. Anything after cleanWs fails with "file not found."

6. **Hidden characters from copy-paste break configs.** Nginx proxy_pass failed from an invisible character. Always verify with `cat -A`.

7. **Deploy over VPC private IP, not public.** Same VPC = faster, more secure. Public IP adds unnecessary external routing.

8. **Trivy flags base image CVEs you can't fix.** Use `.trivyignore` for reviewed exceptions. Fail only on CRITICAL.

9. **Groovy variables don't expand in `sh '''...'''`.** Single-quoted shell blocks are literal. Use `sh """..."""` for Groovy interpolation.

---

## Cost Management

| Resource | Cost | Free Tier |
|----------|------|-----------|
| App Server (t3.micro) | ~₹0 | Yes (750 hrs/month) |
| Jenkins (t3.small) | ~₹1.4/hr | No — stop when done |
| Elastic IPs (running) | ₹0 | Free while attached + running |
| Elastic IPs (stopped) | ~₹3.6/day each | Charged when NOT using |
| EBS Storage | ~₹8/month | 30GB free tier |

**Stop when done:** `aws ec2 stop-instances ...`
**Full teardown:** `terraform destroy`

---

## Resume Bullet Points

> Built an automated deployment system that takes a Node.js API from code to production in ~3 minutes using Jenkins, Docker, and AWS — triggered by a single git push with zero manual intervention.

> Provisioned complete AWS infrastructure (VPC, EC2, Security Groups, IAM, Elastic IPs) using Terraform IaC with modular, version-controlled configurations

> Configured Ansible playbooks with 3 roles for automated server setup and zero-touch application deployment behind Nginx reverse proxy

> Integrated DevSecOps practices with Trivy container vulnerability scanning in strict mode — CRITICAL CVEs block deployment with archived scan reports for audit compliance

> Optimized CI/CD performance on constrained infrastructure: JVM memory caps, 2GB swap, npm socket limits, Docker log rotation, and automated image retention policies

---

## Build Log

Tested with 10+ consecutive pipeline runs including code changes, intentional failures, docs-only changes, and manual triggers. See [docs/pipeline-test-log.md](docs/pipeline-test-log.md).

Full day-by-day journal: [docs/README-daily-log.md](docs/README-daily-log.md)

---

## License

MIT
