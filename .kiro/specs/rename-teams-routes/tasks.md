# Implementation Plan

## Task List

- [x] 1. Update routes.rb — заменить custom routes на resources :teams
  - Заменить `get "/teams", to: "teams#index", as: :teams` и `get "/team", to: "teams#show", as: :team` на `resources :teams, only: [:index, :show]`
  - _Requirements: 1, 5_

- [x] 2. Update TeamsController#set_team — использовать params[:id] вместо params[:name]
  - Изменить `set_team` метод для поиска по `Team.find(params[:id])` вместо `Team.find_by!(name: params[:name])`
  - Удалить fallback на `current_user.team`
  - _Requirements: 1_

- [x] 3. Update application.html.erb — исправить team_path helper с nil-проверкой
  - Изменить `team_path` на `team_path(current_user.team) if current_user.team`
  - Если у пользователя нет команды — ссылка не отображается
  - _Requirements: 3_

- [x] 4. Update units/index.html.erb — исправить team_path helper
  - Изменить `team_path(name: team.name)` на `team_path(team)` в строке 49
  - _Requirements: 3_

- [x] 5. Update users/show.html.erb — исправить team_path helper
  - Изменить `team_path(name: @user.team.name)` на `team_path(@user.team)` в строке 39
  - _Requirements: 3_

- [x] 6. Update units/show.html.erb — исправить team_path helper
  - Изменить `team_path(name: team.name)` на `team_path(team)` в строке 36
  - _Requirements: 3_

- [x] 7. Update teams/index.html.erb — исправить team_path helper
  - Изменить `team_path(name: team.name)` на `team_path(team)` в строке 25
  - _Requirements: 3_

- [x] 8. Update red_zones_details_component.html.erb — исправить team_path helper
  - Изменить `team_path(name: red_zone[:team]&.name)` на `team_path(red_zone[:team])` в строке 41
  - _Requirements: 3_

- [x] 9. Update application_controller.rb — исправить stored_location_for с nil-проверкой
  - Изменить `team_path` на `team_path(current_user.team) if current_user.team`
  - Если у пользователя нет команды — fallback на teams_path
  - _Requirements: 4_

- [x] 10. Update spec/requests/teams_spec.rb — обновить route helpers
  - Заменить `get team_path` на `get team_path(team)` где необходимо
  - Заменить `get team_path, params: {name: team.name}` на `get team_path(team)`
  - _Requirements: 3_

- [x] 11. Run tests — проверить что все тесты проходят
  - `bundle exec rspec spec/requests/teams_spec.rb`
  - `bundle exec rspec` (full suite)
