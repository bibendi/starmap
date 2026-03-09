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
- **Capybara + Cuprite**: System/integration testing

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
- ViewComponent testing: `render_inline` + Capybara matchers for reusable components
- System specs with Capybara + Cuprite
- N+1 testing with `n_plus_one_control` gem:
  - Tag tests with `:n_plus_one`
  - Use `populate` blocks to create data at different scales
  - Example: `bundle exec rspec spec/components/team_member_metrics_component_spec.rb:115 --tag n_plus_one`
- Debugging workflow:
  - Single failure: Use `puts foo.inspect` then run specific test
  - Multiple similar failures: Fix one test first, then run others
  - SQL debugging: `LOG=all bundle exec rspec ...`

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

**Quarterly Data Model**: Immutable past quarters with draft/active states. Ratings editable only in non-archived quarters.

---
_Document patterns and decisions, not exhaustive dependency lists. New code following patterns shouldn't require steering updates._
