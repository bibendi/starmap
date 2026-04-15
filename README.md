# Starmap

[![CI](https://github.com/bibendi/starmap/actions/workflows/ci.yml/badge.svg)](https://github.com/bibendi/starmap/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=for-the-badge)](LICENSE)

Starmap is an open-source web application that makes engineering team competencies visible and manageable. It turns invisible, distributed knowledge into a living map of technical capabilities — so teams can proactively identify risks, plan development, and reduce bus factor.

It is not a control system. Its goal is to help every team member see their progress, understand team priorities, and consciously plan their growth.

<details>
<summary>Screenshots</summary>

<p align="center">
<img src="docs/attachments/team-dashboard.png" width="600" alt="Team Dashboard"><br>
<em>Team Dashboard</em>
</p>

<p align="center">
<img src="docs/attachments/team-competency.png" width="600" alt="Team Competency"><br>
<em>Team Competency</em>
</p>

<p align="center">
<img src="docs/attachments/unit-dashboard.png" width="600" alt="Unit Dashboard"><br>
<em>Unit Dashboard</em>
</p>

</details>

## Quick Start

### Prerequisites

- Ruby 3.3+
- Node.js 20+
- PostgreSQL 15+
- Docker (optional: for PostgreSQL and Keycloak)

### Setup

```bash
git clone https://github.com/bibendi/starmap.git
cd starmap

bundle install
npm install

docker compose up -d          # PostgreSQL and Keycloak (optional)
bin/rails db:setup            # creates DB, runs migrations, loads seed data

bin/dev                        # starts Puma + Vite dev server
```

The app runs at `http://localhost:3000`.

### Authentication

Starmap supports two authentication methods:

**Email and password** — enabled by default, no configuration needed.

**OpenID Connect (OIDC)** — if your organization uses a Single Sign-On provider (Keycloak, Google Workspace, Okta, Auth0, and others), you can enable OIDC login. Set the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `OIDC_CLIENT_ID` | No | Client ID from your SSO provider. When set, enables OIDC login |
| `OIDC_CLIENT_SECRET` | If OIDC enabled | Client secret from your SSO provider |
| `OIDC_ISSUER` | If OIDC enabled | URL of your SSO realm (e.g. `https://auth.example.com/realms/my-org`) |
| `REGISTRATION_ENABLED` | No | Show a "Sign up" link on the login page (`true`/`false`, default: `false`) |

For local development, a pre-configured Keycloak instance is included in `docker-compose.yml`:

```bash
docker compose up -d keycloak   # starts at http://localhost:5101
```

## How It Works

### Competency Scale (0-3)

Every rating answers the question: *"What can I practically do with this technology right now?"*

| Level | Meaning |
|-------|---------|
| **0** | No prior experience. Needs an introduction from scratch |
| **1** | Can work on simple tasks under guidance or pairing with a senior |
| **2** | Can independently pick up a mid-complexity task and ship it to production |
| **3** | Can explain architectural decisions, do code review, and mentor others |

### Quarterly Cycle

Starmap evaluates competencies **retrospectively** — after a quarter ends, not while it's in progress. The process repeats every quarter:

1. **Quarter creation** — an admin creates a new quarter (e.g. "2026 Q1") after it has ended, sets the evaluation window dates
2. **Activation & self-assessment** — the admin activates the quarter; previous quarter's ratings are copied as a starting point. Engineers then rate themselves asynchronously across team technologies during the evaluation window
3. **1-on-1 dialogue** — team lead and engineer discuss ratings, sync on levels, and build a development plan
4. **Close** — the admin closes the quarter; all remaining draft/submitted ratings are auto-approved. The quarter becomes read-only

Quarter lifecycle: `draft` → `active` → `closed` → `archived`

### User Roles

| Role | Scope |
|------|-------|
| **Engineer** | Self-assessment, personal dashboard, action plans |
| **Team Lead** | Team competency matrix, approve ratings, team planning |
| **Unit Lead** | Unit-level metrics, risk reports, strategic development |
| **Admin** | User/technology management, quarter lifecycle, system settings |

## Metrics

Metrics are like a car dashboard — they don't judge the driver, they help navigate. Their purpose is to highlight areas for discussion, not to deliver verdicts.

### Team Health

Four summary metrics give a quick overview:

- **Coverage Index** — answers "Is our team protected if someone leaves?" Shows the percentage of technologies where enough people have expertise. Target: >80%
- **Maturity Index** — answers "Are we growing as a team?" Tracks the average competency level across all technologies over time. Target: >2.0
- **Red Zones** — answers "Where are we most vulnerable?" Lists critical technologies where too few people have expertise, putting delivery at risk
- **Key Person Risks** — answers "Who is carrying too much?" Highlights technologies where only one person has expertise — a burnout risk and a single point of failure

### Individual Growth

- **Competency Dynamics** — answers "Is this engineer growing?" Shows rating change per person compared to the previous quarter. A starting point for 1-on-1 career discussions
- **Universality Index** — answers "Is this person a specialist or a generalist?" Counts how many technologies someone is proficient in. Helps spot T-shaped contributors vs. deep specialists
- **Expertise Concentration** — answers "Is this person overloaded with unique knowledge?" Counts technologies where someone is the only expert. A decrease is good — it means knowledge is being shared

### Skill Matrix

A visual grid of technologies vs. team members with:

- **Bus Factor** — how many experts each technology has compared to the target
- **Coverage %** — what share of the team can work with each technology

## Deployment

Docker images are published to GitHub Container Registry on every release tag:

```bash
docker pull ghcr.io/bibendi/starmap:latest
```

Images are tagged with semver versions (`1.0.0`) and short SHAs.

Required environment variables when running the container:

```bash
docker run -d \
  -p 3000:3000 \
  -e SECRET_KEY_BASE=your-secret \
  -e DATABASE_URL=postgres://user:pass@host:5432/starmap_production \
  ghcr.io/bibendi/starmap:latest
```

## Testing

### Ruby (RSpec)

```bash
bundle exec rspec                           # all tests
bundle exec rspec --tag n_plus_one          # N+1 query tests only
LOG=all bundle exec rspec spec/path:42      # with SQL logging
```

### JavaScript (Vitest)

```bash
npm test                   # all tests
npm run test:watch         # watch mode
npm run test:coverage      # with coverage
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes with tests
4. Run `bundle exec rspec` and `npm test`
5. Run `bundle exec rubocop` and `npm run check:js`
6. Open a Pull Request

## License

MIT — see [LICENSE](LICENSE) for details.
