# Implementation Plan

## Tasks

- [x] 1. Изменить маршруты units в config/routes.rb
- [x] 1.1 Заменить `get "/units"` и `get "/unit"` на `resources :units, only: [:index, :show]`
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Обновить контроллер и ссылки
- [x] 2.1 Изменить `set_unit` в app/controllers/units_controller.rb — искать по `params[:id]` вместо `params[:name]`
  - _Requirements: 1.3_
- [x] 2.2 Изменить `unit_path(name: unit.name)` на `unit_path(unit)` в app/views/units/index.html.erb
  - _Requirements: 1.3_
- [x] 2.3 Обновить логику ссылки в app/views/layouts/application.html.erb — если у пользователя есть unit: ссылка на unit_path(unit), если нет: ссылка на units_path
  - _Requirements: 1.3_

- [x] 3. Проверить маршруты
- [x] 3.1 Запустить `bin/rails routes | grep units` — убедиться в наличии GET /units и GET /units/:id
  - _Requirements: 1.1, 1.2_

- [ ] 4. Проверить работу в браузере
- [ ] 4.1 (P) Проверить GET /units -> UnitsController#index
- [ ] 4.2 (P) Проверить GET /units/:id -> UnitsController#show
- [ ] 4.3 (P) Проверить что несуществующий id возвращает 404