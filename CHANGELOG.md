# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
