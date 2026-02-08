import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['container', 'item', 'prevButton', 'nextButton']
  static values = {
    itemsPerPage: { type: Number, default: 6 },
    currentPage: { type: Number, default: 1 }
  }

  connect() {
    this.updateDisplay()
    this.updateButtons()
  }

  get totalItems() {
    return this.itemTargets.length
  }

  get totalPages() {
    return Math.ceil(this.totalItems / this.itemsPerPageValue)
  }

  next() {
    if (this.currentPageValue < this.totalPages) {
      this.currentPageValue++
      this.updateDisplay()
      this.updateButtons()
    }
  }

  prev() {
    if (this.currentPageValue > 1) {
      this.currentPageValue--
      this.updateDisplay()
      this.updateButtons()
    }
  }

  updateDisplay() {
    const startIndex = (this.currentPageValue - 1) * this.itemsPerPageValue
    const endIndex = startIndex + this.itemsPerPageValue

    this.itemTargets.forEach((item, index) => {
      const isVisible = index >= startIndex && index < endIndex
      item.classList.toggle('hidden', !isVisible)
    })
  }

  updateButtons() {
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = this.currentPageValue === 1
    }

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = this.currentPageValue >= this.totalPages
    }
  }
}
