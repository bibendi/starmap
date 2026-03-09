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
- Automated creation of new cycles with copying of previous ratings
- Status workflow: draft → active → closed → archived
- Editing restrictions based on quarter state ensure data integrity

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
2. **Quarterly Cycle**: Admin/Unit Lead launches new quarter, copies past ratings, notifications sent
3. **Analytics**: Unit Lead tracks Coverage/Maturity/Red Zones, Team Lead monitors team competencies, Engineer tracks personal progress
4. **Risk Management**: Metrics signal gaps; Team Lead and Unit Lead plan expertise exchange
5. **Development**: Action Plans link development goals to quarters, technologies, and employees

## Key Principles

- **Transparency**: Each role sees detail level matching their responsibility (Pundit authorization)
- **Stability**: Focus on even expertise distribution and bus-factor reduction
- **Intentional Development**: Goals captured in Action Plans, progress tracked quarterly

---
_Document patterns and principles, not exhaustive feature lists. New features following existing patterns shouldn't require steering updates._
