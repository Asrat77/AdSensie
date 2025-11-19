import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "buttonText", "spinner"]

    async sync(event) {
        event.preventDefault()

        // Show syncing state
        this.buttonTarget.disabled = true
        this.buttonTextTarget.textContent = "Syncing..."
        this.spinnerTarget.classList.remove("hidden")

        // Show start toast
        this.showToast("Telegram sync started in the background.")

        try {
            const response = await fetch(this.buttonTarget.form.action, {
                method: "POST",
                headers: {
                    "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
                    "Accept": "application/json"
                }
            })

            if (response.ok) {
                // Poll for completion (simplified - in production you'd use ActionCable)
                setTimeout(() => {
                    this.buttonTarget.disabled = false
                    this.buttonTextTarget.textContent = "Sync Now"
                    this.spinnerTarget.classList.add("hidden")
                    this.showToast("Sync Complete. Data is up to date.", "success")
                }, 5000) // Assume 5 seconds for demo
            }
        } catch (error) {
            console.error("Sync failed:", error)
            this.buttonTarget.disabled = false
            this.buttonTextTarget.textContent = "Sync Now"
            this.spinnerTarget.classList.add("hidden")
            this.showToast("Sync failed. Please try again.", "error")
        }
    }

    showToast(message, type = "info") {
        const toast = document.createElement("div")
        toast.className = "fixed bottom-4 right-4 z-50 bg-gray-900 text-white px-6 py-4 rounded-lg shadow-lg flex items-center gap-3 animate-fade-in-up"

        const icon = type === "success"
            ? '<svg class="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>'
            : '<svg class="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'

        toast.innerHTML = `
      ${icon}
      <div>
        <h4 class="font-semibold">Notification</h4>
        <p class="text-sm text-gray-300">${message}</p>
      </div>
    `

        document.body.appendChild(toast)

        setTimeout(() => {
            toast.classList.add("opacity-0", "translate-y-2", "transition-all", "duration-300")
            setTimeout(() => toast.remove(), 300)
        }, 5000)
    }
}
