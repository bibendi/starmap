# Архитектура Starmap

## Системная архитектура

### Общая структура
Starmap построен на Rails 8.1.1 как полноценное веб-приложение с использованием Hotwire (Turbo + Stimulus) для интерактивного пользовательского интерфейса без отдельного frontend фреймворка.

### Архитектурные слои

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer (Hotwire)              │
├─────────────────────────────────────────────────────────────┤
│                   Controllers (Rails MVC)                   │
├─────────────────────────────────────────────────────────────┤
│                  Models (ActiveRecord)                     │
├─────────────────────────────────────────────────────────────┤
│                 Background Jobs (Solid Queue)              │
├─────────────────────────────────────────────────────────────┤
│                  Data Layer (PostgreSQL)                   │
└─────────────────────────────────────────────────────────────┘
```

## Модели данных

### Основные сущности (6 таблиц)

#### User (users)
- **Атрибуты**: id, email, first_name, last_name, display_name, role, team_id, active, ldap_dn, admin, last_ldap_sync_at
- **Роли**: engineer, team_lead, unit_lead, admin
- **Ассоциации**: belongs_to :team, has_many :skill_ratings, has_many :action_plans, has_many :teams (как team_lead)
- **LDAP интеграция**: sync с корпоративным LDAP

#### Team (teams)
- **Атрибуты**: id, name, unit, team_lead_id
- **Ассоциации**: has_many :users, belongs_to :team_lead (User)

#### Technology (technologies)
- **Атрибуты**: id, name, description, category, criticality ('high', 'normal', 'low'), target_experts
- **Критичность**: влияет на требования к количеству экспертов
- **Бизнес-логика**: расчет bus factor risk, coverage analysis

#### Quarter (quarters)
- **Атрибуты**: id, year, quarter_number, start_date, end_date, status ('draft', 'active', 'closed', 'archived')
- **Статус**: контролирует доступность для редактирования оценок

#### SkillRating (skill_ratings)
- **Атрибуты**: id, user_id, technology_id, quarter_id, rating (0-3), approved, approved_by, approved_at
- **Шкала**: 0-3 (0=не знаю, 1=базовый, 2=уверенный, 3=эксперт)
- **Рабочий процесс**: создание → утверждение тимлидом

#### ActionPlan (action_plans)
- **Атрибуты**: id, user_id, technology_id, title, description, status ('active', 'completed', 'paused'), target_quarter_id
- **Статусы**: управляют жизненным циклом планов развития

## Контроллеры

### ApplicationController
- **Роль**: Базовый контроллер для всех
- **Функции**: Devise интеграция, Pundit авторизация, локализация (I18n), security (CSRF protection)
- **Helper методы**: current_user, user_signed_in?

### DashboardsController
- **Три типа дашбордов**:
  - **overview**: общие метрики для всех пользователей
  - **team**: детальная аналитика для тимлидов
  - **personal**: персональные метрики для разработчиков

### Метрики и бизнес-логика

#### Coverage Index
```ruby
# Процент технологий с ≥2 экспертами
covered_technologies = Technology.joins(:skill_ratings)
  .where(skill_ratings: { rating: 2..3 })
  .group(:technology_id)
  .having("COUNT(*) >= 2")
  .count
```

#### Maturity Index
```ruby
# Средняя оценка по всем технологиям
SkillRating.current.average(:rating)&.round(1) || 0
```

#### Red Zones
```ruby
# Критические технологии с недостаточным покрытием
Technology.joins(:skill_ratings)
  .where(criticality: 'high')
  .group(:technology_id)
  .having("COUNT(CASE WHEN skill_ratings.rating >= 2 THEN 1 END) < 2")
  .count
```

#### Key Person Risk
```ruby
# Технологии где сотрудник единственный эксперт
# Используется для выявления рисков зависимости
```

## Авторизация (Pundit)

### Иерархия ролей
- **engineer**: может редактировать собственные оценки, просматривать personal dashboard
- **team_lead**: все права engineer + просмотр team dashboard + утверждение оценок команды
- **unit_lead**: все права team_lead + просмотр overview dashboard + управление юнитом
- **admin**: полные права на все ресурсы

### Базовые политики
- **ApplicationPolicy**: родительский класс со вспомогательными методами для проверки ролей
- **own_record?**: проверка принадлежности записи пользователю
- **same_team?**: проверка принадлежности к одной команде

## Фоновые задачи (Solid Queue)

### LdapSyncJob
- **Назначение**: Синхронизация пользователей с LDAP
- **Частота**: Автоматический запуск каждые 24 часа
- **Процесс**:
  1. Подключение к LDAP
  2. Получение списка пользователей
  3. Создание/обновление/деактивация пользователей
  4. Очистка удаленных пользователей

## Маршруты (Routes)

### Основные пути
```ruby
root "dashboards#overview"
devise_for :users

# Dashboards
/dashboards/overview
/dashboards/team
/dashboards/personal

# Админка
/admin/technologies
/admin/quarters
/admin/users
/admin/teams

# Управление оценками
/skill_ratings
/action_plans

# API для AJAX/Hotwire
/api/v1/metrics
/api/v1/notifications

# Локализация
/(:locale)/*
```

## Интеграции

### LDAP (Net-LDAP)
- **Конфигурация**: `config/ldap.yml`
- **Атрибуты**: uid, cn, givenName, sn, mail, memberOf
- **Аутентификация**: через Devise LDAP
- **Автоматическая синхронизация**: Solid Queue job

### Кеширование
- **Solid Cache**: для кеширования метрик и LDAP данных
- **Время жизни**: настраиваемое для разных типов данных

## Безопасность

### Authentication
- **Devise**: базовая аутентификация
- **LDAP**: корпоративная интеграция
- **Session management**: Rails session + Devise

### Authorization
- **Pundit**: декларативная авторизация
- **Role-based access**: 4-уровневая система ролей
- **Record-level**: проверка принадлежности записей

### Data Protection
- **CSRF**: protection_from_forgery
- **Parameters filtering**: чувствительные данные исключены из логов
- **Secure headers**: настройки безопасности в production

## Производительность

### База данных
- **Eager loading**: includes для предотвращения N+1
- **Индексы**: на критических полях (foreign keys, часто используемые запросы)
- **Scopes**: оптимизированные запросы

### Кеширование
- **Метрики**: кеширование расчетных значений
- **LDAP данные**: временное кеширование
- **Представления**: Hotwire Turbo для частичных обновлений

## Развертывание

### Контейнеризация
- **Docker/Docker Compose**: для development и production
- **Multi-stage build**: оптимизация размера образов

### Мониторинг
- **Logs**: структурированное логирование
- **Health checks**: Rails health endpoint
- **Background jobs**: мониторинг выполнения задач
