import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    const rail = this.element.closest(".flash-rail")
    this.element.remove()

    if (rail && !rail.querySelector(".alert")) rail.remove()
  }
}
