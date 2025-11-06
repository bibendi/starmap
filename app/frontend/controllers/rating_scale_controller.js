import { Controller } from "@hotwired/stimulus"

// Контроллер для интерактивной шкалы оценок 0-3
export default class extends Controller {
  static targets = ["input", "visual", "description"]
  static values = {
    currentRating: { type: Number, default: 0 },
    showDescription: { type: Boolean, default: true }
  }

  static descriptions = {
    0: "Не имею представления - Слышал об этом, но на практике не сталкивался. Нужен онбординг с нуля",
    1: "Имею представление - Могу выполнять простые задачи под присмотром или в паре с коллегой",
    2: "Свободно владею - Могу самостоятельно взять задачу средней сложности и довести ее до production",
    3: "Могу учить других - Могу объяснить архитектурные решения, провести код-ревью и быть ментором"
  }

  connect() {
    this.currentRatingValue = this.currentRatingValue || 0
    this.initializeRating()
    this.updateVisual()
  }

  initializeRating() {
    if (this.hasInputTarget && this.inputTarget.value) {
      this.currentRatingValue = parseInt(this.inputTarget.value) || 0
    }
  }

  // Обработчик клика по звездочке/кружку
  selectRating(event) {
    event.preventDefault()
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.currentRatingValue = rating
    this.updateInput(rating)
    this.updateVisual()
    this.updateDescription()
  }

  // Обработчик наведения мыши
  previewRating(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.updateVisual(rating)
  }

  // Сброс превью при уходе мыши
  resetPreview() {
    this.updateVisual()
  }

  updateInput(rating) {
    if (this.hasInputTarget) {
      this.inputTarget.value = rating
    }
  }

  updateVisual(previewRating = null) {
    const ratingToShow = previewRating !== null ? previewRating : this.currentRatingValue

    if (this.hasVisualTarget) {
      const circles = this.visualTarget.querySelectorAll('[data-rating]')

      circles.forEach(circle => {
        const circleRating = parseInt(circle.dataset.rating)
        const isFilled = circleRating <= ratingToShow

        circle.classList.toggle('bg-blue-500', isFilled && ratingToShow <= 1)
        circle.classList.toggle('bg-green-500', isFilled && ratingToShow === 2)
        circle.classList.toggle('bg-purple-500', isFilled && ratingToShow >= 3)
        circle.classList.toggle('text-white', isFilled)

        circle.classList.toggle('bg-gray-200', !isFilled)
        circle.classList.toggle('text-gray-400', !isFilled)
        circle.classList.toggle('border-gray-300', !isFilled)
      })
    }
  }

  updateDescription() {
    if (this.hasDescriptionTarget && this.showDescriptionValue) {
      const description = RatingScaleController.descriptions[this.currentRatingValue]
      this.descriptionTarget.textContent = description
      this.descriptionTarget.classList.remove('hidden')
    }
  }

  // Метод для программной установки рейтинга
  setRating(rating) {
    this.currentRatingValue = rating
    this.updateInput(rating)
    this.updateVisual()
    this.updateDescription()
  }

  // Метод для получения текущего рейтинга
  getRating() {
    return this.currentRatingValue
  }

  // Валидация перед отправкой формы
  validateRating() {
    if (this.currentRatingValue < 0 || this.currentRatingValue > 3) {
      this.showError('Оценка должна быть в диапазоне от 0 до 3')
      return false
    }

    this.clearError()
    return true
  }

  showError(message) {
    // Можно добавить отображение ошибки в UI
    console.error('Rating validation error:', message)
  }

  clearError() {
    // Очистка ошибок
    console.log('Rating validation cleared')
  }
}
