import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"]

  connect() {
    console.log("Mobile menu controller connected")
  }

  toggle() {
    this.menuTarget.classList.toggle('hidden')
    this.openIconTarget.classList.toggle('hidden')
    this.closeIconTarget.classList.toggle('hidden')
  }
}
