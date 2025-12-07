import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "description"]
  static values = {
    currentRating: { type: Number, default: 0 },
    showDescription: { type: Boolean, default: true },
    debounceMs: { type: Number, default: 500 },
    minRating: { type: Number, default: 0 },
    maxRating: { type: Number, default: 3 }
  }

  connect() {
    this.updateDisplay()
    this.setupKeyboardNavigation()
  }

  disconnect() {
    this.removeKeyboardNavigation()
  }

  setupKeyboardNavigation() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.element.addEventListener("keydown", this.boundHandleKeydown)

    // Make buttons focusable
    const buttons = this.element.querySelectorAll("button[data-rating]")
    buttons.forEach(button => {
      button.setAttribute("tabindex", "0")
    })
  }

  removeKeyboardNavigation() {
    if (this.boundHandleKeydown) {
      this.element.removeEventListener("keydown", this.boundHandleKeydown)
    }
  }

  handleKeydown(event) {
    // Only handle if focus is within the rating scale
    if (!this.element.contains(event.target)) return

    let newRating = this.currentRatingValue

    switch (event.key) {
      case "ArrowRight":
      case "ArrowUp":
        event.preventDefault()
        newRating = Math.min(this.maxRatingValue, this.currentRatingValue + 1)
        this.setRating(newRating)
        break
      case "ArrowLeft":
      case "ArrowDown":
        event.preventDefault()
        newRating = Math.max(this.minRatingValue, this.currentRatingValue - 1)
        this.setRating(newRating)
        break
      case "Home":
        event.preventDefault()
        this.setRating(this.minRatingValue)
        break
      case "End":
        event.preventDefault()
        this.setRating(this.maxRatingValue)
        break
      case "0":
      case "1":
      case "2":
      case "3":
        event.preventDefault()
        const digitRating = parseInt(event.key)
        if (digitRating >= this.minRatingValue && digitRating <= this.maxRatingValue) {
          this.setRating(digitRating)
        }
        break
    }
  }

  setRating(rating) {
    this.currentRatingValue = rating
    if (this.hasInputTarget) {
      this.inputTarget.value = rating
    }
    this.showDescription()
    this.updateDisplay()

    // Focus the button for the selected rating
    const button = this.element.querySelector(`button[data-rating="${rating}"]`)
    if (button) {
      button.focus()
    }
  }

  selectRating(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.setRating(rating)

    // Trigger change event on input for form validation
    if (this.hasInputTarget) {
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  previewRating(event) {
    const previewRating = parseInt(event.currentTarget.dataset.rating)
    this.tempHighlight(event.currentTarget, previewRating)
  }

  resetPreview(event) {
    this.updateDisplay()
  }

  showDescription() {
    if (this.hasDescriptionTarget && this.showDescriptionValue) {
      const desc = this.getDescription(this.currentRatingValue)
      this.descriptionTarget.textContent = desc
      this.descriptionTarget.classList.remove("hidden")
    }
  }

  getDescription(rating) {
    const descriptions = {
      0: "Не имею представления - Слышал об этом, но на практике не сталкивался. Нужен онбординг с нуля",
      1: "Имею представление - Могу выполнять простые задачи под присмотром или в паре с коллегой",
      2: "Свободно владею - Могу самостоятельно взять задачу средней сложности и довести ее до production",
      3: "Могу учить других - Могу объяснить архитектурные решения, провести код-ревью и быть ментором"
    }
    return descriptions[rating] || "Выберите оценку от 0 до 3"
  }

  updateDisplay() {
    const buttons = this.element.querySelectorAll("button[data-rating]")
    buttons.forEach(button => {
      // Remove all rating-related classes
      button.classList.remove(
        "bg-red-50", "text-red-600", "border-red-300", "ring-2", "ring-red-500",
        "bg-yellow-50", "text-yellow-600", "border-yellow-300", "ring-yellow-500",
        "bg-green-50", "text-green-600", "border-green-300", "ring-green-500",
        "bg-blue-50", "text-blue-600", "border-blue-300", "ring-blue-500",
        "bg-gray-50", "text-gray-600", "border-gray-300", "ring-gray-500",
        "scale-110", "shadow-md"
      )

      const rating = parseInt(button.dataset.rating)
      const isSelected = rating === this.currentRatingValue
      const isFilled = rating <= this.currentRatingValue && this.currentRatingValue > 0

      if (isSelected) {
        // Selected rating - highlighted with ring
        const classes = this.getClassesForRating(rating)
        classes.forEach(cls => button.classList.add(cls))
        button.classList.add("ring-2", "scale-110", "shadow-md")
      } else if (isFilled) {
        // Filled but not selected - lighter color
        const classes = this.getClassesForRating(rating)
        classes.forEach(cls => {
          // Make colors lighter
          const lighterClass = cls.replace("50", "25").replace("600", "400")
          button.classList.add(lighterClass || cls)
        })
      } else {
        // Not filled - default gray
        button.classList.add("bg-white", "text-gray-300", "border-gray-200")
      }
    })
  }

  tempHighlight(button, rating) {
    // Remove existing highlights
    button.classList.remove(
      "bg-red-50", "text-red-600", "border-red-300",
      "bg-yellow-50", "text-yellow-600", "border-yellow-300",
      "bg-green-50", "text-green-600", "border-green-300",
      "bg-blue-50", "text-blue-600", "border-blue-300",
      "bg-gray-50", "text-gray-600", "border-gray-300"
    )

    const classes = this.getClassesForRating(rating)
    classes.forEach(cls => button.classList.add(cls))
    button.classList.add("scale-105", "transition-transform")
  }

  getClassesForRating(rating) {
    switch (rating) {
      case 0: return ["bg-gray-50", "text-gray-600", "border-gray-300"]
      case 1: return ["bg-yellow-50", "text-yellow-600", "border-yellow-300"]
      case 2: return ["bg-green-50", "text-green-600", "border-green-300"]
      case 3: return ["bg-blue-50", "text-blue-600", "border-blue-300"]
      default: return ["bg-gray-50", "text-gray-600", "border-gray-300"]
    }
  }
}
