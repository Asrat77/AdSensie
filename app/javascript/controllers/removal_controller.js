import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        setTimeout(() => {
            this.remove()
        }, 5000)
    }

    remove() {
        this.element.classList.add('opacity-0', 'translate-y-2')
        setTimeout(() => {
            this.element.remove()
        }, 300)
    }
}
