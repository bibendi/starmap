<!--
Sync Impact Report
==================
Version change: N/A (new) → 1.0.0

Modified principles: N/A (initial ratification)

Added sections:
  - Core Principles (5 principles)
  - Security & Data Integrity
  - Development Workflow
  - Governance

Removed sections: N/A (initial ratification)

Templates requiring updates:
  ✅ .specify/templates/plan-template.md — no changes needed (Constitution Check
     gate is generic; references align with principles)
  ✅ .specify/templates/spec-template.md — no changes needed (requirements and
     acceptance criteria sections are principle-agnostic)
  ✅ .specify/templates/tasks-template.md — no changes needed (task categories
     cover testing, implementation, and polish)
  ✅ .specify/templates/checklist-template.md — no changes needed (generic)
  ✅ .specify/templates/agent-file-template.md — no changes needed (auto-generated)
  ✅ .specify/templates/constitution-template.md — no changes needed (source
     template preserved as-is)

Follow-up TODOs: None
-->

# Starmap Constitution

## Core Principles

### I. Server-Rendered First

All views MUST be server-rendered HTML using Rails ERB templates with
ViewComponent. JavaScript MUST be limited to Stimulus controllers for
progressive enhancement. Turbo Frames and Turbo Streams MUST be used for
partial page updates and real-time server-push scenarios. Single-page
application frameworks (React, Vue, Angular) MUST NOT be introduced.

Rationale: Server-rendered HTML with Hotwire reduces JavaScript complexity,
improves accessibility, simplifies testing, and aligns with the team's
monolithic Rails architecture.

### II. Authorization on Every Action

Every controller action MUST enforce authorization via Pundit policies before
any business logic executes. Policies MUST cover all four roles (Engineer,
Team Lead, Unit Lead, Admin) with clear record-level access rules. No public
controller actions are permitted without a corresponding policy check.

Rationale: Role-based access control is a core business requirement. Starmap
exposes sensitive competency data; unauthorized access would compromise the
integrity of self-assessments, approval workflows, and analytics.

### III. Small, Focused Code

Methods MUST target fewer than 5 lines. Classes and modules MUST have a single
responsibility. Flat inheritance hierarchies are preferred; deep inheritance
or metaprogramming MUST be avoided without explicit justification in a code
review. Meaningful names that reveal intent MUST be used over abbreviations.

Rationale: Follows POODR and Refactoring Ruby Edition principles. Small
methods with clear names reduce cognitive load, ease testing, and enable safe
refactoring as the competency management domain evolves.

### IV. Behavior-Driven Testing

Tests MUST use factories (FactoryBot), never fixtures. Test assertions MUST
verify observable behavior and rendered output, never internal implementation
details. Ruby tests MUST use RSpec. Stimulus controller tests MUST use Vitest
with JSDOM. Tests tagged `:n_plus_one` MUST use `n_plus_one_control` to
validate query performance at multiple data scales.

Rationale: Behavior-focused tests remain stable across refactoring. Factory-
based data avoids inter-test coupling. N+1 guards prevent performance regressions
as dashboards accumulate more metrics and data.

### V. Simplicity Over Cleverness

YAGNI principles MUST be applied; features not needed today MUST NOT be
built. Native Rails 8 solutions (Solid Queue, Solid Cache) MUST be preferred
over external dependencies (Redis, Sidekiq). New gem additions MUST be
justified by a concrete problem that existing stack cannot solve. Complex
abstractions (repository pattern, service objects as intermediaries) MUST NOT
be introduced unless direct ActiveRecord usage is demonstrably insufficient.

Rationale: Starmap is a monolithic Rails application. External dependencies
increase operational overhead and onboarding friction. Simple, idiomatic Rails
code maximizes maintainability for a team focused on domain logic.

## Security & Data Integrity

- All data mutations MUST be audited via the Audited gem where applicable.
- Sensitive data (passwords, tokens) MUST be filtered from structured logs.
- CSRF protection and secure headers MUST remain enabled on all endpoints.
- SQL injection and XSS prevention MUST rely on Rails built-in mechanisms;
raw SQL MUST be avoided unless parameterized queries are used explicitly.
- Quarterly data in closed or archived states MUST be immutable; no rating
  modifications are permitted.

## Development Workflow

- All code changes MUST pass `bundle exec rspec` before merge.
- All Stimulus controller changes MUST pass `npm test` before merge.
- RuboCop violations MUST be resolved; no inline disables without a
  code-review comment explaining why.
- Commits MUST follow conventional commit format
  (`type(scope): description`).
- CSS MUST follow the component-based system defined in `docs/STYLEGUIDE.md`.
  All components MUST support dark mode.
- Brakeman security analysis MUST pass with no high-severity findings.

## Governance

- This constitution is the authoritative source of project standards and
  supersedes all other practice documents.
- Amendments MUST document the version bump rationale (MAJOR for backward-
  incompatible changes, MINOR for new principles or expanded guidance, PATCH
  for clarifications).
- All pull requests MUST be verified for compliance with these principles.
- Complexity introduced that violates a principle MUST be justified with a
  concrete rationale documented in the PR description or `AGENTS.md`.
- Runtime development guidance for AI agents is maintained in `AGENTS.md`,
  which MUST stay consistent with this constitution.

**Version**: 1.0.0 | **Ratified**: 2026-03-31 | **Last Amended**: 2026-03-31
