import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    this.buttonTarget.addEventListener("click", (e) => {
      e.preventDefault()
      this.toggleMenu()
    })

    document.addEventListener("click", (e) => {
      if (!this.element.contains(e.target)) {
        this.menuTarget.style.display = "none"
      }
    })
  }

  toggleMenu() {
    if (this.menuTarget.style.display === "block") {
      this.menuTarget.style.display = "none"
    } else {
      this.menuTarget.style.display = "block"
    }
  }
}
