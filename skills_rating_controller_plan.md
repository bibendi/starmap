# План реализации SkillRatingsController

## Цель
Создать контроллер для управления системой оценок компетенций по шкале 0-3 с поддержкой Hotwire, процессом утверждения тимлидами и копированием между кварталами.

## Архитектура контроллера

### Основные действия
1. **index** - список оценок с фильтрацией по пользователю/технологии/кварталу
2. **show** - детальный просмотр оценки
3. **new/create** - создание новой оценки
4. **edit/update** - редактирование оценки
5. **destroy** - удаление (только для админов)
6. **approve/reject** - утверждение/отклонение оценок тимлидами
7. **copy_from_previous** - копирование оценок из предыдущего квартала

### Фильтрация и представления
- **user_ratings** - оценки конкретного пользователя
- **team_ratings** - оценки всей команды
- **technology_ratings** - оценки по конкретной технологии
- **quarter_ratings** - оценки за конкретный квартал
- **pending_approvals** - ожидающие утверждения оценки

### Hotwire интеграция
- Turbo Frames для обновления отдельных блоков
- Turbo Streams для real-time обновлений
- Stimulus контроллеры для интерактивности

### Валидации безопасности
- Проверка статуса квартала (только draft/active)
- Ролевая модель через Pundit
- Защита от редактирования утвержденных оценок

## Структура файлов

### Контроллер
```
app/controllers/skill_ratings_controller.rb
```

### Представления
```
app/views/skill_ratings/
├── index.html.erb                 # Основной список оценок
├── show.html.erb                  # Детальный просмотр
├── new.html.erb                   # Создание оценки
├── edit.html.erb                  # Редактирование оценки
├── _form.html.erb                 # Форма оценки
├── _rating_card.html.erb          # Карточка оценки для Turbo
├── _approval_panel.html.erb       # Панель утверждения
├── _history.html.erb              # История изменений
├── user_ratings.html.erb          # Оценки пользователя
├── team_ratings.html.erb          # Оценки команды
├── technology_ratings.html.erb    # Оценки технологии
├── pending_approvals.html.erb     # Ожидающие утверждения
└── shared/
    ├── _skill_scale.html.erb      # Шкала оценок 0-3
    └── _rating_status.html.erb    # Статус оценки
```

### Stimulus контроллеры
```
app/javascript/controllers/
├── skill_rating_controller.js     # Основной контроллер оценок
├── rating_scale_controller.js     # Интерактивная шкала 0-3
├── approval_workflow_controller.js # Контроллер утверждения
└── rating_history_controller.js   # История оценок
```

### Помощники
```
app/helpers/skill_ratings_helper.rb
```

## Ключевые функции контроллера

### 1. Контроль доступа
```ruby
def require_active_quarter
  @quarter = Quarter.find(params[:quarter_id] || Quarter.current.id)
  redirect_to root_path, alert: "Оценки можно вводить только в активных кварталах" unless @quarter.active?
end
```

### 2. Создание и обновление
```ruby
def create
  @skill_rating = SkillRating.new(skill_rating_params)
  @skill_rating.created_by = current_user
  @skill_rating.quarter = Quarter.current

  if @skill_rating.save
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@skill_rating, partial: "skill_ratings/rating_card") }
      format.html { redirect_to skill_ratings_path, notice: "Оценка создана" }
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

### 3. Утверждение оценок
```ruby
def approve
  @skill_rating = SkillRating.find(params[:id])

  if @skill_rating.approve!(current_user)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@skill_rating, partial: "skill_ratings/rating_card") }
      format.html { redirect_to @skill_rating, notice: "Оценка утверждена" }
    end
  else
    redirect_to @skill_rating, alert: "Ошибка утверждения оценки"
  end
end
```

### 4. Копирование из предыдущего квартала
```ruby
def copy_from_previous
  @from_quarter = @quarter.previous_quarter
  return redirect_to skill_ratings_path, alert: "Нет предыдущего квартала" unless @from_quarter

  copied_count = SkillRating.copy_ratings_to_new_quarter(@from_quarter, @quarter, current_user)

  redirect_to skill_ratings_path, notice: "Скопировано #{copied_count} оценок из #{@from_quarter.full_name}"
end
```

## Компоненты пользовательского интерфейса

### 1. Интерактивная шкала 0-3
- Визуальные индикаторы уровней
- Описания для каждого уровня
- Возможность выбора с помощью кликов/клавиатуры

### 2. Панель утверждения
- Кнопки "Утвердить"/"Отклонить"
- Поле для комментариев
- Индикатор статуса утверждения

### 3. Карточка оценки
- Информация о пользователе/технологии
- Текущая оценка
- История изменений
- Кнопки управления (редактировать/утвердить/отклонить)

### 4. Фильтры и навигация
- Фильтр по кварталам
- Фильтр по технологиям
- Фильтр по статусам (draft/submitted/approved)
- Пагинация для больших списков

## Интеграция с дашбордами

### Personal Dashboard
- Показ собственных оценок пользователя
- Прогресс заполнения оценок
- Индикаторы требующих внимания оценок

### Team Dashboard
- Оценки всей команды
- Статистика по технологиям
- Ожидающие утверждения оценки

### Overview Dashboard
- Общие метрики по командам
- Критические технологии
- Риски зависимости от ключевых специалистов

## Производительность

### 1. Кеширование
- Кеширование расчетных метрик
- Кеширование списков оценок
- Redis для временного кеша

### 2. Оптимизация запросов
- Eager loading связанных данных
- Пагинация для больших списков
- Индексы на критических полях

### 3. Background Jobs
- Копирование оценок между кварталами в фоне
- Расчет статистики и метрик
- Уведомления о необходимости оценок

## Безопасность

### 1. Авторизация
- Pundit политики для всех действий
- Проверка принадлежности команды
- Защита от CSRF атак

### 2. Валидация данных
- Серверная валидация шкалы оценок
- Проверка статуса квартала
- Ограничение на редактирование утвержденных оценок

### 3. Аудит
- Логирование всех изменений
- Отслеживание кто и когда изменил оценку
- История всех операций

## Тестирование

### 1. Unit тесты
- Тестирование валидаций модели
- Тестирование бизнес-логики
- Тестирование вспомогательных методов

### 2. Интеграционные тесты
- Тестирование CRUD операций
- Тестирование процесса утверждения
- Тестирование копирования между кварталами

### 3. Функциональные тесты
- Тестирование с разными ролями
- Тестирование Hotwire интеграции
- Тестирование пользовательских сценариев

## Следующие шаги
1. Создание SkillRatingsController
2. Создание базовых представлений
3. Добавление Stimulus контроллеров
4. Интеграция с дашбордами
5. Написание тестов
