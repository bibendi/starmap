# Starmap Product Overview

Starmap is a corporate web application for managing technical team competencies, employee development, and reducing bus-factor risks. The system automates collection, validation, and analysis of engineering team competencies through quarterly cycles.

## Core Value Proposition

- **Proactive Risk Management**: Identify knowledge silos and single points of failure before they become critical
- **Objective Assessment**: Standardized 0-3 competency scale eliminates subjective evaluations
- **Transparent Development**: Clear growth paths with measurable progress by quarters
- **Strategic Planning**: Data-driven decisions on hiring, training, and team composition

## User Roles & Responsibilities

### Engineer
- **Tasks**: Self-assessment of competencies in active quarters, initiating Action Plans
- **Tools**: Personal dashboard, self-assessment forms, rating history, development plans
- **Contributions**: Provides data for Coverage Index and Key Person Risk metrics
- **Focus**: Personal progress, career navigation, motivation

### Team Lead
- **Tasks**: Approve and adjust ratings, team development planning, mentorship
- **Tools**: Team dashboard with skill matrices, approval interface, Action Plan builder
- **Contributions**: Reduces Key Person Risk, improves Coverage/Maturity Index
- **Focus**: Team development, skill balance, bus-factor reduction

### Unit Lead
- **Tasks**: Unit metrics overview, redistribution expertise decisions, training investments
- **Tools**: Overview dashboard, risk reports, quarterly dynamics analysis
- **Contributions**: Controls Coverage Index, reduces Red Zones, strategic development
- **Focus**: Unit-level strategy, critical technology alignment

### Admin / HR
- **Tasks**: Maintain technology catalog and criticality, user role management, quarter cycle control
- **Tools**: Admin panel, Solid Queue settings, audit via Audited gem
- **Contributions**: Data integrity, timely quarter/background processes
- **Focus**: Process improvement, security and access management

## Core Capabilities

**Competency Management System**
- 0-3 rating scale with clear level descriptions
- Self-assessment → Team Lead approval workflow
- Historical tracking of competency development by quarters
- Role-based validation and Quarter state constraints

**Quarterly Cycles**
- Quarters are created **retrospectively**, after the evaluated period has ended
- Previous quarter's ratings are copied as a starting point when a quarter is activated
- Status workflow: draft → active → closed → archived
- Evaluation window (`evaluation_start_date`..`evaluation_end_date`) opens **after** the quarter's `end_date`
- Editing restrictions based on quarter state and evaluation period ensure data integrity

**Analytics Dashboards**
- **Overview Dashboard**: Unit-level metrics and risks for leadership
- **Team Dashboard**: Detailed competency matrices and dynamics
- **Personal Dashboard**: Individual progress and development tracking

**Development Planning (Action Plans)**
- Created based on identified competency gaps
- Progress tracking: active → completed/paused
- Linked to target quarters, technologies, and users

## Business Metrics

### Coverage Index
Percentage of technologies with ≥2 experts (rating 2-3). Goal: >80% for stable team.

### Maturity Index
Average competency level across all technologies (0.0 - 3.0). Goal: >2.0 for mature team.

### Red Zones
Critical technologies (high criticality) with insufficient coverage (<2 experts).

### Key Person Risk
Technologies where a single employee is the only expert.

### Action Plan Progress
Status tracking of development plans linked to quarters and technologies.

## Role Interactions

1. **Data Collection**: Engineer updates self-ratings → Team Lead validates and approves → data flows to metrics
2. **Quarterly Cycle**: Admin creates quarter retrospectively after period ends, activates it (copies past ratings as starting point), notifications sent
3. **Analytics**: Unit Lead tracks Coverage/Maturity/Red Zones, Team Lead monitors team competencies, Engineer tracks personal progress
4. **Risk Management**: Metrics signal gaps; Team Lead and Unit Lead plan expertise exchange
5. **Development**: Action Plans link development goals to quarters, technologies, and employees

## Key Principles

- **Transparency**: Each role sees detail level matching their responsibility (Pundit authorization)
- **Stability**: Focus on even expertise distribution and bus-factor reduction
- **Intentional Development**: Goals captured in Action Plans, progress tracked quarterly

---

# Technology Stack

## Architecture Overview

**Monolithic Rails Application** with domain-driven organization. Five-layer architecture:

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation (Hotwire: Turbo + Stimulus + ViewComponent)    │
├─────────────────────────────────────────────────────────────┤
│ Controllers (Rails MVC)                                     │
├─────────────────────────────────────────────────────────────┤
│ Models (ActiveRecord with business logic)                   │
├─────────────────────────────────────────────────────────────┤
│ Background Jobs (Solid Queue)                               │
├─────────────────────────────────────────────────────────────┤
│ Data Layer (PostgreSQL)                                     │
└─────────────────────────────────────────────────────────────┘
```

## Core Stack

- **Language**: Ruby 3.2+
- **Framework**: Ruby on Rails 8.1.1
- **Web Server**: Puma
- **Frontend**: Hotwire (Turbo + Stimulus) - server-rendered HTML, minimal JavaScript
- **Database**: PostgreSQL 15+
- **Localization**: I18n (en, ru), Europe/Moscow timezone
- **Logging**: Structured logging for debugging and monitoring

## Key Libraries

### Authentication & Authorization
- **Devise**: Authentication with database strategy, devise-i18n for localization
- **Pundit**: Role-based and record-level authorization (Engineer, Team Lead, Unit Lead, Admin)

### Data & Background Processing
- **Solid Queue**: Native Rails 8 background job processing (no Redis required)
- **Solid Cache**: Native Rails 8 caching
- **Audited**: Change tracking for audit trails

### UI & Components
- **ViewComponent 4.2.0**: Reusable, testable UI components
- **Vite Rails**: Asset management
- **Kaminari**: Pagination
- **Component CSS System**: Custom CSS instead of inline Tailwind classes
- **Dark Mode**: All components must support dark mode
- **Style Guide**: Follow docs/STYLEGUIDE.md for template development

### Development & Quality
- **Brakeman**: Security analysis
- **Annotate**: Model documentation
- **RuboCop**: Ruby codestyle enforcement
- **Letter Opener**: Development email viewing
- **debug gem**: Structured debugging

### Testing
- **RSpec**: BDD testing framework
- **FactoryBot**: Test data factories (not fixtures)
- **Shoulda Matchers**: Rails-specific matchers
- **test-prof**: Test profiling and optimization
- **n_plus_one_control**: N+1 query testing with tagged tests

### Infrastructure
- **Docker + Docker Compose**: Multi-stage container builds
- **Puma**: Web server
- **PostgreSQL 15+**: Database

### JavaScript Testing
- **Vitest + JSDOM**: Stimulus controller testing
- **@rails/request.js**: AJAX requests
- **@hotwired/stimulus**: Controller framework

## Data Model

### Core Entities

**User**: Accounts with roles (engineer, team_lead, unit_lead, admin), team associations
**Team**: User groups with Team Lead management
**Technology**: Technologies with category, criticality level, target expert count
**Quarter**: Quarterly cycles with status (draft → active → closed → archived)
**SkillRating**: Competency ratings (0-3), approval status, quarter linkage
**ActionPlan**: Development plans linking users, technologies, and target quarters

### Business Logic Patterns

**Quarter State Machine**: All ratings tied to Quarter status. Editing restricted by state.

**Authorization Pattern**: Pundit policies enforce role-based access. Controllers check policies before actions.

**Background Processing**: Metric recalculation (Coverage Index, Maturity Index, Red Zones, Key Person Risk) via Solid Queue jobs after rating changes.

**Caching**: Metric results cached in Solid Cache for dashboard performance.

## Development Standards

### Ruby Conventions
- Standard Ruby codestyle with RuboCop
- POODR (Practical Object Oriented Design in Ruby) principles
- Small methods (< 5 lines ideal), meaningful names
- Single responsibility per class/method
- Dependency injection over hard-coded dependencies

### Testing Philosophy

**Ruby (RSpec)**:
- Factory-based test data (not fixtures)
- `let_it_be` (from test-prof) for all shared test data — see [Factory Best Practices](#factory-best-practices) below
- N+1 testing with `n_plus_one_control` gem:
  - Tag tests with `:n_plus_one`
  - Use `populate` blocks to create data at different scales
  - Example: `bundle exec rspec spec/components/team_member_metrics_component_spec.rb:115 --tag n_plus_one`
- Debugging workflow:
  - Single failure: Use `puts foo.inspect` then run specific test
  - Multiple similar failures: Fix one test first, then run others
  - SQL debugging: `LOG=all bundle exec rspec ...`
  - Slow tests or large output: redirect output to temporary file and navigate along it

**JavaScript (Vitest + JSDOM)**:
- Minimalist approach: create DOM structure, register controllers, test behavior via DOM interaction
- Test location: `test/controllers/` directory
- Testing helpers in `test/helpers/`:
  - `stimulus.js`: `renderController()`, `waitForStimulus()` for controller initialization
  - `testing-library.js`: `getByTestId()`, `userEvent()` for data-testid based testing
  - `fetch.js`: `mockFetch()`, `createCSRFToken()` for HTTP mocking and CSRF
- Testing principles:
  - Test behavior, not implementation
  - Use `data-testid` for stable element selection (stable API)
  - Verify visibility/state of elements, not internal details

### Factory Best Practices

**Why `let_it_be` instead of `let` or `before { create }`**

`let_it_be` (from test-prof) creates records **once** per describe/context group and reuses them across all examples inside. This avoids redundant DB writes and bcrypt hashing on every test.

- `let` recreates the record for **every** `it` block
- `before { create }` recreates records for **every** `it` block
- `let_it_be` creates the record **once** and wraps each test in a transaction rollback, so tests stay isolated

**Rules:**

1. Declare ALL `let_it_be` at the **top level** of `RSpec.describe` — never inside nested `context` or `describe` blocks. This ensures records are created once for the entire spec file.
2. Use `let_it_be` only for records **shared across multiple tests**. If a record is used in a single test, use `let` inside the relevant context — don't pollute the top level with single-use variables.
3. Prefer `build` over `create` when persistence is not required. Policy tests, component rendering, and validation checks often don't need DB-persisted records — `build(:user)` is instant, `create(:user)` triggers bcrypt.
4. Use `before { create }` only for records that are **specific to a particular test scenario**. These are lightweight associations without expensive callbacks.
5. Name variables descriptively to avoid collisions — e.g., `user_in_team2` instead of reusing `user2` with different semantics across contexts.

**Example:**

```ruby
RSpec.describe MyComponent, type: :component do
  # Shared across multiple tests — let_it_be at top level
  let_it_be(:team) { create(:team) }
  let_it_be(:team2) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:user_in_team2) { create(:user, team: team2) }

  context "scenario A" do
    before do
      create(:skill_rating, user: user, technology: tech, quarter: quarter)
    end
    # ...
  end

  context "scenario B — single-use record" do
    # Used only here — keep as `let`, no need for let_it_be
    let(:other_user) { create(:engineer, team: team2) }
    # ...
  end

  context "policy check — no DB needed" do
    # No persistence required — use `build` instead of `create`
    let(:record) { build(:user, team: nil) }
    # ...
  end
end
```

### Debugging

**Ruby**:
- **debug gem**: Structured debugging with breakpoints
- **Structured logging**: For production monitoring and development traceability
- **Letter Opener**: View development emails in browser
- **SQL logging**: Set `LOG=all` environment variable for query analysis

**Testing**:
- Fix one failing test before addressing batch failures with similar errors
- Use `puts foo.inspect` for quick variable inspection in specs

### Security
- CSRF protection, XSS prevention, SQL injection protection
- Secure headers, sensitive data filtering in logs
- Pundit authorization on all controller actions
- Audit trail via Audited gem

## Common Commands

```bash
# Development
bin/dev

# Database
bin/rails db:migrate
bin/rails db:seed
bin/rails db:seed:replant

# Testing Ruby
bundle exec rspec
LOG=all bundle exec rspec  # with SQL logging
bundle exec rspec --tag n_plus_one

# Testing JavaScript
npm test
npm run test:watch
npm run test:coverage

# Security
bundle exec brakeman
```

## Key Technical Decisions

**Hotwire over SPA**: Server-rendered HTML with Turbo Frames/Streams reduces JavaScript complexity while providing modern UX.

**ViewComponent Pattern**: Reusable UI components for dashboard cards, metrics, forms. Testable with render_inline.

**Solid Queue/Caching**: Native Rails 8 solutions eliminate external Redis dependency.

**Role-based Authorization**: Four distinct roles with Pundit policies enforcing granular permissions.

**Quarterly Data Model**: Quarters created retrospectively after the period ends. Evaluation window opens after quarter's `end_date`. Ratings editable only during evaluation period of active quarters.

---

# Project Structure

## IMPORTANT CONSTRAINTS

**NEVER traverse above the project root directory**. All file reads, writes, and searches must stay within this directory. This is a hard rule — do not violate it.

## Organization Philosophy

**Standard Rails MVC** with domain-driven organization. Core entities (User, Team, Technology, Quarter) drive folder structure. Features organized by domain concern rather than technical layer.

## Directory Patterns

### Models (`app/models/`)
**Location**: `app/models/`
**Purpose**: Domain entities with business logic, validations, and associations
**Example**: `User` (roles: engineer, team_lead, unit_lead, admin), `SkillRating` (0-3 scale with approval workflow)

### Controllers (`app/controllers/`)
**Location**: `app/controllers/`
**Purpose**: HTTP request handling, parameter filtering, policy enforcement
**Example**: `SkillRatingsController` manages rating lifecycle, `TeamsController` for team management

### Components (`app/components/`)
**Location**: `app/components/`
**Purpose**: Reusable UI components using ViewComponent gem
**Example**: `CoverageIndexComponent`, `RedZonesCardComponent`, `TeamSkillMatrixComponent`

### Policies (`app/policies/`)
**Location**: `app/policies/`
**Purpose**: Pundit authorization rules - role-based and record-level access
**Example**: `SkillRatingPolicy` (edit own ratings in active quarters), `DashboardPolicy` (role-based dashboard access)

### Query Objects (`app/queries/`)
**Location**: `app/queries/`
**Purpose**: Encapsulate complex database queries (multi-table JOINs, subqueries, aggregations) outside of models and components
**Example**: `RedZonesQuery` (count and details for red zone metrics)
**Naming**: PascalCase with `Query` suffix (e.g., `RedZonesQuery`, `KeyPersonRisksQuery`)
**Convention**:
- Accept parameters via `initialize` (e.g., `teams:`, `quarter:`)
- Expose one or more public methods that return data (e.g., `#count`, `#details`)
- Use model scopes for reusable filtering; keep multi-query orchestration in the query object
- Every Query Object MUST include an N+1 test (tagged `:n_plus_one`) for each public method, verifying constant query count as data scales
- Tests go in `spec/queries/`

### Jobs (`app/jobs/`)
**Location**: `app/jobs/`
**Purpose**: Solid Queue background job classes
**Example**: Metric recalculation jobs after rating changes

### JavaScript (`app/frontend/`)
**Location**: `app/frontend/`
**Purpose**: Stimulus controllers and Turbo integration
**Example**: `app/frontend/controllers/` directory for Stimulus, minimal JavaScript philosophy

### Tests (`spec/`, `test/`)
**Location**: `spec/` for Ruby, `test/` for JavaScript
**Purpose**: RSpec for Ruby (factories, models, components, system tests), Vitest for Stimulus controllers
**Example**: Component specs with `render_inline`, Stimulus tests with JSDOM

## Naming Conventions

- **Models**: PascalCase (e.g., `SkillRating`, `ActionPlan`)
- **Controllers**: snake_case with `_controller` suffix (e.g., `skill_ratings_controller.rb`)
- **Components**: PascalCase with `Component` suffix (e.g., `RedZonesCardComponent`)
- **Policies**: snake_case with `_policy` suffix matching model (e.g., `skill_rating_policy.rb`)
- **Database Tables**: snake_case, plural (e.g., `skill_ratings`, `action_plans`)

## Import Organization

### Ruby
```ruby
# No custom path aliases - standard Rails autoloading
# Standard library first
require 'some_gem'

# Then gems
require 'devise'
require 'pundit'

# Application code autoloaded by Rails
```

### JavaScript
```javascript
// Stimulus controllers use standard import maps
import { Controller } from "@hotwired/stimulus"
import { get, post } from "@rails/request.js"
```

## Critical Patterns

### Stimulus Controller Registration
Creating a file in `app/frontend/controllers/` is NOT enough. Every new controller MUST be manually imported AND registered in `app/frontend/entrypoints/application.js`:
```javascript
import TeamMembersController from "../controllers/team_members_controller"
application.register("team-members", TeamMembersController)
```
Use kebab-case for the controller name in `register()` and `data-controller="..."`.

### Stimulus Optional Targets
`static targets` declares REQUIRED targets — if missing from DOM, Stimulus throws "Missing target element" on connect. For optional targets, use a getter with `querySelector` instead:
```javascript
get addSelectElement() {
  return this.element.querySelector('[data-my-controller-target="addSelect"]')
}
```

### Rails Empty Array Params
When all hidden inputs with `name="model[field][]"` are removed from the DOM, the param is completely absent from `params`. To ensure Rails always parses it as an array, include a marker hidden input with empty value:
```erb
<%= hidden_field_tag "model[field][]", "", id: nil %>
```
Controller then uses `.reject(&:blank?)` to get an empty array.

### Transactional Controller Actions
When a controller action performs multiple data mutations (e.g., sync associations + update attributes), they MUST be wrapped in a single `ActiveRecord::Base.transaction`. Without it, partial updates can persist when a later validation fails. Operations that change DB state required by validations MUST run first:
```ruby
Model.transaction do
  model.sync_associations!(ids)   # changes DB state needed by validation
  model.update!(attrs)             # validates against updated state
end
```

### Devise Turbo Compatibility
All Devise `button_to` calls (sign out, OIDC authorize) MUST include `data: { turbo: false }`. Without it, Turbo intercepts the redirect and the action silently fails:
```erb
<%= button_to "Sign out", destroy_user_session_path, method: :delete, data: { turbo: false } %>
```

### OIDC Discovery with HTTP
Gem `swd` (dependency of `openid_connect`) defaults to `URI::HTTPS` for discovery. For HTTP-based OIDC providers (dev Keycloak), set `SWD.url_builder = URI::HTTP` before mounting OmniAuth middleware. Without it, discovery silently fails with SSL errors.

### ActiveRecord Query Separation
Components and controllers MUST NOT contain complex database queries. Follow this layering:

1. **Reusable scopes on models** — simple filtering conditions used across multiple contexts:
   ```ruby
   # app/models/skill_rating.rb
   scope :expert_ratings, -> { where(rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING) }
   ```
2. **Query Objects** — complex queries with JOINs, subqueries, or multi-step aggregation live in `app/queries/`:
   ```ruby
   # app/queries/red_zones_query.rb
   class RedZonesQuery
     def initialize(teams:, quarter: Quarter.current)
     def count    # single aggregate result
     def details  # structured data for rendering
   end
   ```
3. **Controllers** — call Query Objects and pass results to views as instance variables:
   ```ruby
   # app/controllers/teams_controller.rb
   def show
     @red_zones_count = RedZonesQuery.new(teams: [@team], quarter: @current_quarter).count
     @red_zones_data = RedZonesQuery.new(teams: [@team], quarter: @current_quarter).details
   end
   ```
4. **Components** — purely presentational. Accept pre-computed data via required `initialize` parameters, contain NO database queries:
   ```ruby
   # app/components/red_zones_card_component.rb
   def initialize(red_zones_count:, label: nil, description: nil)
     @red_zones_count = red_zones_count
   end
   ```
5. **Views** — NEVER call model classes directly (no `Model.where(...)`, `Model.pluck(...)`, `Model.includes(...)` in templates)

**Data flow**: Controller → Query Object → DB → instance variable → View → Component (render only).

**Why**: Query Objects are independently testable, reusable across controllers, and keep component rendering specs fast (pass pre-computed data, no DB hits).

## Code Organization Principles

**Single Responsibility**: Small methods (< 5 lines), focused classes. Each model/controller/component has one clear purpose.

**Policy Enforcement**: All controller actions check Pundit policies. Policies encapsulate role logic (Engineer, Team Lead, Unit Lead, Admin).

**Quarter State Machine**: All ratings tied to Quarter with statuses (draft → active → closed → archived). Business logic respects quarter state for edit permissions.

**Component Reusability**: Dashboard cards and metrics as ViewComponents. Components accept data objects, render HTML, contain no business logic.

**Testing Philosophy**:
- Behavior testing over implementation details
- Component tests verify rendered output
- Stimulus tests verify DOM interactions, not internal APIs
- Factory-based test data, not fixtures
