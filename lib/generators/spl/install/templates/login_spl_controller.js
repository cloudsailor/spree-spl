import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["checkbox", "loginForm", "registrationForm"]

    connect() {
        this.toggle()
    }

    toggle() {
        if (!this.hasCheckboxTarget) return

        if (this.checkboxTarget.checked) {
            this.loginFormTarget.classList.remove("hidden")
            this.registrationFormTarget.classList.add("hidden")
        } else {
            this.loginFormTarget.classList.add("hidden")
            this.registrationFormTarget.classList.remove("hidden")
        }
    }
}
