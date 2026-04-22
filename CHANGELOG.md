# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.7.0] - 2026-04-22

### Added

- Historical chart popup for Maturity Index — click the metric card on team/unit dashboards to view maturity index values for past quarters as a bar chart (0.0–3.0 scale)
- Coverage Index historical chart popup — click the metric card to view coverage index trends across past quarters

### Fixed

- Correct Stimulus action syntax in DialogComponent

## [0.6.0] - 2026-04-20

### Added

- Show rating change indicator compared to previous quarter on skill ratings page
- Dynamic level description update when rating changes in edit form
- Soft archive for team technologies instead of hard delete to preserve historical ratings

## [0.5.0] - 2026-04-20

### Changed

- Upgrade Rails 8.1.1 → 8.1.3 and Devise 4.9.4 → 5.0.3

### Removed

- Unused Redis service from docker-compose (project uses Solid Queue with PostgreSQL)

## [0.4.0] - 2026-04-18

### Changed

- Extract component SQL into domain-oriented query objects (RedZones, TeamMemberMetrics, SkillMatrix)
- Remove ExpertConstants initializer, use SkillRating constants instead
- Reuse TeamSkillMatrixQuery in TeamTechnologiesController

### Fixed

- Make key person risks N+1 test data deterministic

## [0.3.0] - 2026-04-18

### Added

- Yabeda metrics with Prometheus exporter

### Fixed

- Skip copying ratings for users no longer on the team during quarter activation

## [0.2.3] - 2026-04-17

### Changed

- Add diagnostic output to Docker entrypoint script

## [0.2.2] - 2026-04-17

### Changed

- Docker: move ENTRYPOINT into CMD to allow external entrypoint overrides
- Docker: change working directory from `/rails` to `/app`

### Added

- Makefile targets for running production Docker image (`run-prod`, `shell-prod`, `logs-prod`)

## [0.2.1] - 2026-04-17

### Added

- Public Docker image published to Docker Hub

## [0.2.0] - 2026-04-17

### Changed

- Metrics components now show all rating statuses for the current quarter (draft, submitted, approved, rejected); only approved ratings are shown for past quarters
- Extracted `visible_for_quarter` / `visible_for_quarters` scopes and status constants into `SkillRating` model to centralize filtering logic

## [0.1.0] - 2026-04-16

First release of Starmap — a corporate web application for managing technical team competencies, employee development, and reducing bus-factor risks.

### Core Features

- Competency management with 0-3 rating scale
- Retrospective quarterly evaluation cycles (draft → active → closed → archived)
- Self-assessment → Team Lead approval workflow
- Previous quarter ratings copied as starting point on activation
- Role-based access control (Engineer, Team Lead, Unit Lead, Admin)
- Analytics dashboards: Coverage Index, Maturity Index, Red Zones, Key Person Risk
- Development planning via Action Plans

### Tech Stack

- Ruby on Rails 8.1, Hotwire (Turbo + Stimulus), ViewComponent
- PostgreSQL, Solid Queue, Solid Cache
- Pundit authorization, Devise authentication
- RSpec + Vitest test suites
