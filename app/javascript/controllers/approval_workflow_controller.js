import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "comment", "reason", "submitButton", "closeButton"]
  static values = {
    actionType: String, // "approve" or "reject"
    requireComment: { type: Boolean, default: false }
  }

  connect() {
    // Close modal on Escape key
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundHandleEscape)

    // Close modal on backdrop click
    this.boundHandleBackdropClick = this.handleBackdropClick.bind(this)
    if (this.hasModalTarget) {
      this.modalTarget.addEventListener("click", this.boundHandleBackdropClick)
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
    if (this.hasModalTarget) {
      this.modalTarget.removeEventListener("click", this.boundHandleBackdropClick)
    }
  }

  open(event) {
    if (event) {
      event.preventDefault()
      const actionType = event.currentTarget.dataset.actionType || this.actionTypeValue
      this.actionTypeValue = actionType

      // Find modal by action type and skill rating ID
      const skillRatingId = event.currentTarget.closest('[data-skill-rating-id]')?.dataset.skillRatingId
      if (skillRatingId) {
        const modalId = actionType === "approve"
          ? `approval_modal_${skillRatingId}`
          : `reject_modal_${skillRatingId}`

        const modal = document.getElementById(modalId)
        if (modal) {
          // Get the controller instance from the modal
          const modalController = this.application.getControllerForElementAndIdentifier(modal, "approval-workflow")
          if (modalController) {
            modalController.actionTypeValue = actionType
            modalController.showModal()
            return
          }
        }
      }
    }

    // Fallback: show modal if controller is on the modal itself
    this.showModal()
  }

  showModal() {
    // Show modal
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      this.modalTarget.classList.add("flex")

      // Focus first input if exists
      if (this.hasCommentTarget) {
        setTimeout(() => this.commentTarget.focus(), 100)
      } else if (this.hasReasonTarget) {
        setTimeout(() => this.reasonTarget.focus(), 100)
      }
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.classList.remove("flex")
    }

    // Reset form
    if (this.hasFormTarget) {
      this.formTarget.reset()
    }

    // Clear validation errors
    this.clearValidationErrors()
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.hasModalTarget && !this.modalTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  handleBackdropClick(event) {
    // Close if clicking on backdrop (not on modal content)
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  validate(event) {
    if (this.actionTypeValue === "reject" && this.requireCommentValue) {
      const comment = this.hasCommentTarget ? this.commentTarget.value.trim() : ""
      const reason = this.hasReasonTarget ? this.reasonTarget.value.trim() : ""

      if (!comment && !reason) {
        event.preventDefault()
        this.showValidationError("Необходимо указать причину отклонения")
        return false
      }
    }

    this.clearValidationErrors()
    return true
  }

  submit(event) {
    if (!this.validate(event)) {
      return
    }

    // Disable submit button to prevent double submission
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
    }

    // Form will be submitted via Turbo
    // Modal will be closed by Turbo Stream response
  }

  handleSuccess(event) {
    // This will be called after successful Turbo Stream response
    this.close()

    // Re-enable submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }

  handleError(event) {
    // Re-enable submit button on error
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }

    // Show error message if needed
    this.showValidationError("Произошла ошибка при выполнении действия")
  }

  showValidationError(message) {
    this.clearValidationErrors()

    if (this.hasFormTarget) {
      const errorDiv = document.createElement("div")
      errorDiv.className = "mt-2 text-sm text-red-600"
      errorDiv.setAttribute("data-approval-workflow-target", "error")
      errorDiv.textContent = message

      // Insert after form or at the beginning
      this.formTarget.appendChild(errorDiv)
    }
  }

  clearValidationErrors() {
    if (this.hasFormTarget) {
      const errors = this.formTarget.querySelectorAll("[data-approval-workflow-target='error']")
      errors.forEach(error => error.remove())
    }
  }
}
