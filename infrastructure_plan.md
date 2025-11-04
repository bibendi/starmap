# План настройки инфраструктуры Starmap

## Анализ текущего состояния

### Текущая конфигурация:
- Rails 8.1.1 (базовая версия)
- PostgreSQL (настроен)
- API-only режим (нужно изменить на full-stack)
- Минимальные зависимости

### Необходимые изменения:

## 1. Обновление Gemfile

### Основные зависимости:
```ruby
# Аутентификация и авторизация
gem "devise"
gem "devise-ldap_authenticatable"
gem "pundit" # или action_policy

# Hotwire для интерактивности
gem "hotwire-rails"

# Фоновые задачи
gem "solid_queue"
gem "solid_cache"

# Аудит и версионирование
gem "audited"

# Утилиты
gem "net-ldap"
gem "ruby-ldap"

# Тестирование
gem "rspec-rails"
gem "factory_bot_rails"
gem "shoulda-matchers"
gem "capybara"
gem "selenium-webdriver"

# Разработка
gem "letter_opener"
gem "annotate"
```

## 2. Изменение конфигурации Rails

### config/application.rb:
- Убрать `config.api_only = true`
- Добавить поддержку views, assets, helpers
- Включить Action Mailer, Action Cable, Active Storage

### config/environments/:
- Настроить development, test, production окружения
- Добавить конфигурацию для Solid Queue
- Настроить email для development

## 3. Создание структуры директорий

```
app/
├── controllers/
│   ├── concerns/
│   ├── admin/          # Админ панель
│   ├── dashboards/     # Дашборды
│   └── api/           # API endpoints (если нужны)
├── models/
│   ├── concerns/
│   └── concerns/      # Business logic concerns
├── views/
│   ├── layouts/
│   ├── dashboards/
│   ├── technologies/
│   ├── users/
│   └── action_plans/
├── javascript/
│   ├── controllers/   # Stimulus controllers
│   └── channels/      # Action Cable channels
├── jobs/              # Background jobs
├── policies/          # Pundit policies
├── services/          # Business logic services
└── mailers/           # Email templates
```

## 4. Настройка базы данных

### Миграции для основных таблиц:
- users (с LDAP полями)
- technologies
- quarters
- skill_ratings
- action_plans
- teams
- team_memberships

### Индексы для производительности:
- По user_id, technology_id, quarter_id
- По team_id для быстрого поиска команд
- По criticality для фильтрации

## 5. Конфигурация LDAP

### config/ldap.yml:
```yaml
development:
  host: ldap.company.com
  port: 389
  base_dn: dc=company,dc=com
  attribute: uid
  admin_user: cn=admin,dc=company,dc=com
  admin_password: password
```

## 6. Настройка Solid Queue

### config/queues.yml:
```yaml
default: &default
  concurrency: 5
  queues:
    - "*"

critical:
  <<: *default
  concurrency: 10
  queues:
    - critical
```

## 7. Создание базовых контроллеров

### ApplicationController:
- Аутентификация через Devise
- Pundit authorization
- Current user helper

### DashboardsController:
- Overview dashboard
- Team dashboard
- Personal dashboard

## 8. Настройка маршрутов

### config/routes.rb:
```ruby
Rails.application.routes.draw do
  devise_for :users
  root "dashboards#overview"

  namespace :admin do
    resources :technologies
    resources :quarters
    resources :users
  end

  resources :dashboards do
    collection do
      get :overview
      get :team
      get :personal
    end
  end

  resources :skill_ratings
  resources :action_plans
end
```

## 9. Создание базовых views

### layouts/application.html.erb:
- Навигация по ролям
- Hotwire integration
- Responsive design

### Dashboards views:
- Overview dashboard с таблицами рисков
- Team dashboard с оценками команды
- Personal dashboard с личными метриками

## 10. JavaScript и CSS

### app/javascript/application.js:
- Turbo integration
- Stimulus controllers
- Chart.js для графиков

### app/assets/stylesheets/:
- Bootstrap или Tailwind CSS
- Компоненты для дашбордов
- Responsive design

## Следующие шаги:
1. Обновить Gemfile и установить зависимости
2. Изменить конфигурацию Rails
3. Создать базовую структуру директорий
4. Настроить базу данных и миграции
5. Создать базовые модели и контроллеры

## Roadmap выполнения

### ✅ Этап 1: Настройка инфраструктуры (ЗАВЕРШЕН)
- [x] Обновлен Gemfile с зависимостями (Devise, Pundit, Hotwire, Solid Queue, Audited, LDAP)
- [x] Изменена конфигурация Rails (убран api_only, добавлены railties)
- [x] Создана структура директорий (controllers, views, jobs, policies, services)
- [x] Создан ApplicationController с Devise и Pundit интеграцией
- [x] Создан DashboardsController с логикой для Overview, Team, Personal дашбордов
- [x] Настроены маршруты в config/routes.rb
- [x] Создана миграция для таблицы users с LDAP полями

### ✅ Этап 2: Настройка базы данных PostgreSQL (ЗАВЕРШЕН)
- [x] Создана миграция users (с LDAP полями, Devise, ролевой моделью)
- [x] Создана миграция teams (с тимлидами, LDAP группами)
- [x] Создана миграция technologies (с критичностью, категориями)
- [x] Создана миграция quarters (квартальные циклы, даты, статусы)
- [x] Создана миграция skill_ratings (оценки 0-3, утверждение, блокировка)
- [x] Создана миграция action_plans (планы действий, привязки, прогресс)
- [x] Запустить миграции
- [x] Создать seed данные

### ✅ Этап 3: Настройка аутентификации LDAP и ролевой модели (ЗАВЕРШЕН)
- [x] Настроить Devise с LDAP
- [x] Создать LDAP конфигурацию
- [x] Создать Pundit policies для ролевой модели
- [x] Настроить LDAP sync job
- [x] Создать тестовых пользователей

### 📋 Этап 4: Создание основных моделей системы
- [x] Создать модель User
- [x] Создать модель Team
- [x] Создать модель Technology
- [x] Создать модель Quarter
- [x] Создать модель SkillRating
- [x] Создать модель ActionPlan
- [x] Настроить ассоциации между моделями
- [x] Добавить валидации

### 📋 Этап 5: Реализация системы оценок компетенций (0-3 шкала)
- [ ] Создать контроллер SkillRatings
- [ ] Реализовать логику шкалы 0-3
- [ ] Создать формы для редактирования оценок
- [ ] Добавить валидации для оценок
- [ ] Создать методы для копирования оценок между кварталами

### 📋 Этап 6: Создание квартальных циклов и управления ими
- [ ] Создать контроллер Quarters
- [ ] Реализовать логику создания нового квартала
- [ ] Создать job для копирования оценок
- [ ] Добавить блокировку оценок после завершения квартала
- [ ] Создать методы для получения текущего/предыдущего квартала

### 📋 Этап 7: Разработка дашбордов и аналитики
- [ ] Создать views для Overview Dashboard
- [ ] Создать views для Team Dashboard
- [ ] Создать views для Personal Dashboard
- [ ] Реализовать расчет метрик (Coverage Index, Maturity Index, Red Zones)
- [ ] Добавить графики и визуализации
- [ ] Создать селектор кварталов

### 📋 Этап 8: Реализация системы планов действий (Action Plans)
- [ ] Создать контроллер ActionPlans
- [ ] Создать формы для создания/редактирования планов
- [ ] Реализовать привязку к технологиям и пользователям
- [ ] Добавить отслеживание прогресса (в работе/выполнено/отложено)
- [ ] Создать уведомления о планах

### 📋 Этап 9: Настройка фоновых задач для расчетов метрик
- [ ] Создать job для расчета метрик
- [ ] Создать job для LDAP синхронизации
- [ ] Создать job для уведомлений
- [ ] Настроить Solid Queue
- [ ] Добавить периодические задачи

### 📋 Этап 10: Система уведомлений и интеграция с Mattermost
- [ ] Создать mailer для email уведомлений
- [ ] Настроить интеграцию с Mattermost
- [ ] Создать шаблоны уведомлений
- [ ] Добавить настройки уведомлений для пользователей

### 📋 Этап 11: Пользовательский интерфейс с Hotwire
- [ ] Создать layout application.html.erb
- [ ] Добавить навигацию по ролям
- [ ] Создать Stimulus controllers
- [ ] Добавить Turbo streams для обновления данных
- [ ] Стилизация с CSS/Tailwind
- [ ] Адаптивный дизайн

### 📋 Этап 12: Покрытие тестами
- [ ] Настроить RSpec
- [ ] Создать factory_bot factories
- [ ] Написать unit тесты для моделей
- [ ] Написать integration тесты для контроллеров
- [ ] Написать feature тесты для пользовательских сценариев
- [ ] Настроить CI/CD

### 📋 Этап 13: Финальная интеграция и тестирование системы
- [ ] End-to-end тестирование всех функций
- [ ] Тестирование производительности
- [ ] Проверка безопасности
- [ ] Создание документации
- [ ] Подготовка к деплою
- [ ] Настройка Docker/Docker Compose

## Текущий статус: Этап 3 завершен, готов к Этапу 4 - Создание основных моделей системы

## Созданные миграции:
1. `20251103212524_create_users.rb` - Пользователи с LDAP и Devise
2. `20251104074538_create_teams.rb` - Команды и тимлиды
3. `20251104074554_create_technologies.rb` - Технологии и критичность
4. `20251104074618_create_quarters.rb` - Квартальные циклы
5. `20251104074742_create_skill_ratings.rb` - Оценки компетенций
6. `20251104074848_create_action_plans.rb` - Планы действий

Все миграции включают необходимые индексы для производительности и соответствуют техническому заданию Starmap.
