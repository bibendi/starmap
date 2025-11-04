import { Controller } from "@hotwired/stimulus"

// Контроллер для интерактивных фильтров и поиска
export default class extends Controller {
  static targets = ["search", "user", "status", "submit"]
  static values = {
    autoSubmit: { type: Boolean, default: false },
    debounceMs: { type: Number, default: 300 }
  }

  connect() {
    this.debounceTimer = null
    this.setupEventListeners()
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  setupEventListeners() {
    // Автоотправка при изменении поиска
    if (this.hasSearchTarget && this.autoSubmitValue) {
      this.searchTarget.addEventListener('input', this.debouncedSubmit.bind(this))
    }

    // Автоотправка при изменении селектов
    [this.userTarget, this.statusTarget].forEach(target => {
      if (target && this.autoSubmitValue) {
        target.addEventListener('change', this.submitForm.bind(this))
      }
    })
  }

  debouncedSubmit() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    this.debounceTimer = setTimeout(() => {
      this.submitForm()
    }, this.debounceMsValue)
  }

  submitForm() {
    const form = this.element.closest('form')
    if (form) {
      form.requestSubmit(this.submitTarget)
    }
  }

  // Метод для ручной отправки формы
  onSubmit(event) {
    if (!this.autoSubmitValue) {
      return
    }

    event.preventDefault()
    this.submitForm()
  }

  // Очистка фильтров
  clearFilters() {
    if (this.hasSearchTarget) {
      this.searchTarget.value = ''
    }

    if (this.hasUserTarget) {
      this.userTarget.selectedIndex = 0 // Сбрасываем на "Все пользователи"
    }

    if (this.hasStatusTarget) {
      this.statusTarget.selectedIndex = 0 // Сбрасываем на "Все статусы"
    }

    this.submitForm()
  }

  // Быстрые фильтры для технологий по критичности
  filterByCriticality(event) {
    const criticality = event.target.dataset.criticality
    // Здесь можно добавить логику фильтрации по критичности
    console.log('Фильтр по критичности:', criticality)
  }

  // Фильтр по ролям пользователей
  filterByRole(event) {
    const role = event.target.dataset.role
    console.log('Фильтр по роли:', role)
  }
}
