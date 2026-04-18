# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
