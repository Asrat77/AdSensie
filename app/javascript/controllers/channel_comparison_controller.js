import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "checkbox"]

  connect() {
    // Rebuild selection state from DOM to handle Turbo restoration
    this.selected = new Set()

    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.textContent.trim() === 'Selected') {
        this.selected.add(checkbox.dataset.channelId)
      }
    })

    console.log('Comparison controller connected', this.selected)
    this.updateButtonState()
  }

  toggle(event) {
    event.preventDefault()
    const button = event.currentTarget
    const channelId = button.dataset.channelId

    if (this.selected.has(channelId)) {
      this.selected.delete(channelId)
      this.markAsUnselected(button)
    } else {
      if (this.selected.size < 5) {
        this.selected.add(channelId)
        this.markAsSelected(button)
      } else {
        alert('You can compare up to 5 channels at a time')
      }
    }

    this.updateButtonState()
  }

  markAsSelected(button) {
    button.classList.remove('bg-gray-50', 'text-gray-600')
    button.classList.add('bg-indigo-100', 'text-indigo-700')
    button.textContent = 'Selected'
  }

  markAsUnselected(button) {
    button.classList.remove('bg-indigo-100', 'text-indigo-700')
    button.classList.add('bg-gray-50', 'text-gray-600')
    button.textContent = 'Compare'
  }

  updateButtonState() {
    if (!this.hasButtonTarget) return

    const count = this.selected.size

    if (count > 1) {
      const params = Array.from(this.selected).map(id => `channel_ids[]=${id}`).join('&')
      this.buttonTarget.href = `/channels/compare?${params}`
      this.buttonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.buttonTarget.textContent = `Compare ${count} Channels`
    } else {
      this.buttonTarget.href = '#'
      this.buttonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.buttonTarget.textContent = 'Select channels to compare'
    }
  }
}
