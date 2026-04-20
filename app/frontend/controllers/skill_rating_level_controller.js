import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["levelText"]

  static values = {
    levels: Object
  }

  change(event) {
    const rating = event.target.dataset.rating
    if (rating !== undefined && this.levelTextTarget) {
      this.levelTextTarget.textContent = this.levelsValue[rating] || ""
    }
  }
}
